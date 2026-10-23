import { setTimeout as delay } from 'node:timers/promises';

export async function stopOwnedServer(child, state, signalLocalServer) {
  const closing = {
    active: true,
    shutdownAttempted: false,
    deadline: 0,
    phase: 'control',
    firstWindowReady: false,
  };
  function onControlReady(message) {
    if (message?.type !== 'runtime-server:control-ready' || message.pid !== child.pid) return;
    if (
      !closing.active ||
      state.exited ||
      !child.connected ||
      performance.now() >= closing.deadline
    )
      return;
    state.controlReady = true;
    if (closing.phase === 'control') closing.firstWindowReady = true;
    requestShutdown(child, state, closing);
  }
  child.on('message', onControlReady);
  let inspectionError;
  try {
    const firstWindowReady = await waitForControl(child, state, closing);
    if (state.exited) return;
    if (firstWindowReady && (await waitForServerExit(child, state, closing))) return;
    for (const signal of ['SIGTERM', 'SIGKILL']) {
      if (state.exited) return;
      requestShutdown(child, state, closing);
      inspectionError = signalLocalServer(child, state, signal) ?? inspectionError;
      if (await waitForServerExit(child, state, closing)) return;
    }
    throw new AggregateError(
      [state.controlError, inspectionError].filter(Boolean),
      'Owned local performance server did not exit; no other process was signalled.',
    );
  } finally {
    closing.active = false;
    child.removeListener('message', onControlReady);
  }
}

function requestShutdown(child, state, closing) {
  if (
    !closing.active ||
    closing.shutdownAttempted ||
    state.exited ||
    !child.connected ||
    !state.controlReady ||
    performance.now() >= closing.deadline
  )
    return;
  closing.shutdownAttempted = true;
  try {
    child.send({ type: 'runtime-server:shutdown' }, (error) => {
      if (error && closing.active && performance.now() < closing.deadline) {
        recordControlFailure(state, error);
      }
    });
  } catch (error) {
    recordControlFailure(state, error);
  }
}

function recordControlFailure(state, error) {
  state.controlError =
    state.controlError && state.controlError !== error
      ? new AggregateError([state.controlError, error], 'Owned server control failed.')
      : error;
}

async function waitForControl(child, state, closing) {
  closing.deadline = performance.now() + state.shutdownTimeoutMs;
  closing.firstWindowReady = state.controlReady && child.connected;
  requestShutdown(child, state, closing);
  while (
    !state.exited &&
    !state.controlReady &&
    child.connected &&
    performance.now() < closing.deadline
  ) {
    await delay(Math.max(1, Math.min(10, closing.deadline - performance.now())));
  }
  return closing.firstWindowReady;
}

async function waitForServerExit(child, state, closing) {
  closing.phase = 'exit';
  closing.deadline = performance.now() + state.shutdownTimeoutMs;
  requestShutdown(child, state, closing);
  if (state.exited) return true;
  let timer;
  try {
    return await Promise.race([
      state.exit.then(() => true),
      new Promise((resolve) => {
        timer = setTimeout(() => resolve(false), state.shutdownTimeoutMs);
      }),
    ]);
  } finally {
    clearTimeout(timer);
  }
}
