export {};

declare global {
  interface Window {
    __runtimeVitals: {
      cumulativeLayoutShift: number;
      largestContentfulPaint: number;
      longTasks: number[];
    };
    __flutterScrollSample: {
      done: boolean;
      intervals: number[];
      routeHashes: string[];
    };
  }
}
