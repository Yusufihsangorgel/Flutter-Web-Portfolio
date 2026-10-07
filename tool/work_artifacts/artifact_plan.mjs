import { renderArchitectureBoard, renderCompactArchitectureBoard } from './architecture_boards.mjs';
import { renderCompactLandscapeBoard } from './compact_landscape_board.mjs';
import { renderCompactReleaseBoard } from './compact_release_board.mjs';
import { renderCompactDorseBoard, renderDorseBoard } from './dorse_boards.mjs';
import { renderGatewayBoard } from './gateway_board.mjs';
import { renderConstellationBoard, renderLiveCapture } from './product_boards.mjs';
import { renderReleaseBoard } from './release_board.mjs';

export const artifactJobs = [
  {
    render: renderLiveCapture,
    config: {
      source: 'fugasoft-solutions.png',
      output: 'fugasoft-product.jpg',
      accessibleName: 'FugaSoft live product website',
    },
  },
  { render: renderDorseBoard },
  {
    render: renderReleaseBoard,
    config: {
      output: 'aydinlik-release.jpg',
      eyebrow: 'APP STORE RELEASE',
      title: 'Aydınlık\nE-Gazete',
      descriptor: 'Daily edition, archive and audio reader',
      platform: 'iOS · version 3.1.2',
      icon: 'aydinlik-icon.jpg',
      screens: [
        {
          file: 'aydinlik-edition.png',
          label: 'DAILY EDITION',
        },
        {
          file: 'aydinlik-reader.jpg',
          label: 'AUDIO READER',
        },
      ],
      palette: {
        paper: '#f2efe7',
        ink: '#151515',
        accent: '#c80808',
        stage: '#171717',
        stageInk: '#f8f5ed',
        rule: '#aaa69e',
      },
    },
  },
  {
    render: renderReleaseBoard,
    config: {
      output: 'bilim-utopya-release.jpg',
      eyebrow: 'APP STORE RELEASE',
      title: 'Bilim ve\nÜtopya',
      descriptor: 'Issue reader and subscriber archive',
      platform: 'iOS · version 1.0.1',
      icon: 'bilim-icon.jpg',
      screens: [
        {
          file: 'bilim-cover.jpg',
          label: 'LISTING ISSUE',
        },
        {
          file: 'bilim-archive.png',
          label: 'SUBSCRIBER ARCHIVE',
        },
      ],
      palette: {
        paper: '#f5f0e2',
        ink: '#171717',
        accent: '#e6b900',
        stage: '#ffd83d',
        stageInk: '#171717',
        rule: '#a7975e',
      },
    },
  },
  { render: renderGatewayBoard },
  {
    render: renderArchitectureBoard,
    config: {
      output: 'queue-inspector.png',
      eyebrow: 'QUEUE INSPECTION',
      title: 'One interface.\nThree backends.',
      descriptor:
        'Six read-only MCP tools inspect Asynq, BullMQ, and Sidekiq without direct Redis editing.',
      stages: ['MCP CLIENT', '6 READ-ONLY TOOLS', 'ASYNQ · BULLMQ · SIDEKIQ', 'REDIS'],
      footer: 'github.com/Yusufihsangorgel/queue-inspector-mcp',
      footerLeft: 'TYPESCRIPT · MCP · REDIS',
      footerRight: 'READ-ONLY BY DEFAULT',
      palette: { paper: '#dce9ff', ink: '#111820', accent: '#1e51ff' },
    },
  },
  {
    render: renderArchitectureBoard,
    config: {
      output: 'redis-task-queue.png',
      eyebrow: 'SERVER-SIDE DART',
      title: 'Weighted work.\nExplicit failures.',
      descriptor:
        'A Redis-backed Dart queue with weighted scheduling, retries, and an explicit dead-letter path.',
      stages: ['ENQUEUE', 'WEIGHTED QUEUE', 'WORKER', 'RETRY POLICY', 'DEAD LETTER'],
      footer: 'github.com/Yusufihsangorgel/redis_task_queue',
      footerLeft: 'DART · REDIS',
      footerRight: 'RETRIES · DEAD LETTERS',
      palette: { paper: '#f2e6da', ink: '#171311', accent: '#b82418' },
    },
  },
  {
    render: renderArchitectureBoard,
    config: {
      output: 'portfolio-current.jpg',
      eyebrow: 'FLUTTER WEB RUNTIME',
      title: 'Canonical data.\nLocalized runtime.',
      descriptor:
        'Canonical data, complete locale overlays, accessible Flutter UI, Dart Wasm output, and browser regression tests.',
      stages: ['CANONICAL CONTENT', '7 LOCALES', 'FLUTTER UI', 'DART WASM · SKWASM', 'PLAYWRIGHT'],
      footer: 'developeryusuf.com · production architecture',
      footerLeft: 'FLUTTER 3.47.5 · DART WASM',
      footerRight: '7 LOCALES · PLAYWRIGHT',
      palette: { paper: '#f2eee5', ink: '#12110f', accent: '#1e51ff' },
    },
  },
  { render: renderConstellationBoard },
  {
    render: renderCompactLandscapeBoard,
    config: {
      source: 'fugasoft-solutions.png',
      output: 'fugasoft-product-compact.jpg',
      eyebrow: 'OFFICIAL PRODUCT LINE',
      title: 'FugaSoft',
      descriptor: 'ERP and point-of-sale product family · fugasoft.com',
      palette: {
        paper: '#f2eee7',
        ink: '#151515',
        accent: '#ed0051',
        stage: '#ffffff',
        stageInk: '#151515',
      },
      position: 'center top',
      fit: 'cover',
    },
  },
  { render: renderCompactDorseBoard },
  {
    render: renderCompactReleaseBoard,
    config: {
      output: 'aydinlik-release-compact.jpg',
      eyebrow: 'APP STORE RELEASE',
      title: 'Aydınlık E-Gazete',
      descriptor: 'Daily edition and audio reader',
      platform: 'iOS · version 3.1.2',
      icon: 'aydinlik-icon.jpg',
      screens: ['aydinlik-edition.png', 'aydinlik-reader.jpg'],
      palette: {
        paper: '#f2efe7',
        ink: '#151515',
        accent: '#c80808',
        stage: '#171717',
        stageInk: '#f8f5ed',
      },
    },
  },
  {
    render: renderCompactReleaseBoard,
    config: {
      output: 'bilim-utopya-release-compact.jpg',
      eyebrow: 'APP STORE RELEASE',
      title: 'Bilim ve Ütopya',
      descriptor: 'Issue reader and subscriber archive',
      platform: 'iOS · version 1.0.1',
      icon: 'bilim-icon.jpg',
      screens: ['bilim-cover.jpg', 'bilim-archive.png'],
      palette: {
        paper: '#f5f0e2',
        ink: '#171717',
        accent: '#e6b900',
        stage: '#ffd83d',
        stageInk: '#171717',
      },
    },
  },
  {
    render: renderCompactArchitectureBoard,
    config: {
      output: 'queue-inspector-compact.jpg',
      eyebrow: 'QUEUE INSPECTION',
      title: 'Queue Inspector MCP',
      descriptor: 'Six read-only tools across Asynq, BullMQ, and Sidekiq',
      stages: ['MCP CLIENT', 'READ-ONLY TOOLS', '3 QUEUE ADAPTERS', 'REDIS'],
      palette: {
        paper: '#dce9ff',
        ink: '#111820',
        accent: '#1e51ff',
        stage: '#0d141c',
        stageInk: '#dce9ff',
      },
    },
  },
  {
    render: renderCompactArchitectureBoard,
    config: {
      output: 'go-multitenant-gateway-compact.jpg',
      eyebrow: 'REQUEST PIPELINE',
      title: 'Multi-tenant Gateway',
      descriptor: 'Explicit middleware order in one Go binary',
      stages: ['PUBLIC HEALTH', 'TENANT CONTEXT', 'RATE LIMIT', 'JWT AUTH', 'MODULE'],
      palette: {
        paper: '#dce9ff',
        ink: '#111820',
        accent: '#1e51ff',
        stage: '#0c1218',
        stageInk: '#dce9ff',
      },
    },
  },
  {
    render: renderCompactArchitectureBoard,
    config: {
      output: 'redis-task-queue-compact.jpg',
      eyebrow: 'SERVER-SIDE DART',
      title: 'Redis Task Queue',
      descriptor: 'Server-side Dart queue with retries and dead letters',
      stages: ['ENQUEUE', 'WEIGHTED QUEUE', 'WORKER', 'RETRY POLICY', 'DEAD LETTER'],
      palette: {
        paper: '#dce9ff',
        ink: '#111820',
        accent: '#1e51ff',
        stage: '#0d141c',
        stageInk: '#dce9ff',
      },
    },
  },
  {
    render: renderCompactLandscapeBoard,
    config: {
      renderedBoard: 'constellation-demo.png',
      output: 'constellation-demo-compact.jpg',
      eyebrow: 'OPEN ENGINEERING',
      title: 'Constellation Particles',
      descriptor: 'A reusable Flutter rendering package in motion',
      palette: {
        paper: '#dff8f2',
        ink: '#101820',
        accent: '#1f9d8b',
        stage: '#07111c',
        stageInk: '#dff8f2',
      },
      position: 'center',
      fit: 'cover',
    },
  },
  {
    render: renderCompactArchitectureBoard,
    config: {
      output: 'portfolio-current-compact.jpg',
      eyebrow: 'FLUTTER WEB RUNTIME',
      title: 'Flutter Web Portfolio',
      descriptor: 'Canonical content to localized, tested browser output',
      stages: ['CONTENT', '7 LOCALES', 'FLUTTER UI', 'DART WASM', 'PLAYWRIGHT'],
      palette: {
        paper: '#f2eee5',
        ink: '#12110f',
        accent: '#1e51ff',
        stage: '#f2eee5',
        stageInk: '#12110f',
      },
    },
  },
];

export async function renderArtifacts(renderer) {
  for (const job of artifactJobs) await job.render(renderer, job.config);
}
