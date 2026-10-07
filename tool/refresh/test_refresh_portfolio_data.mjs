import './test_refresh_packages.mjs';
import './test_refresh_writing.mjs';
import { runIncidentTests } from './incident.test.mjs';
import { test, samplePackage, reportResults } from './test_support.mjs';

runIncidentTests(test, samplePackage);
reportResults();
