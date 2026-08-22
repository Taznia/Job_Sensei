import { z } from 'zod';

import {
  IMPORT_SOURCES,
  importJobs,
  importStatus,
} from '../services/jobImport.service.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { ok } from '../utils/apiResponse.js';

/**
 * Job import endpoints — Module 2 (Adreed Saadad Hasan, 22301190).
 *
 * The import writes to the shared job collection, so triggering it is limited
 * to admins and recruiters. Reading the status is open, because it exposes only
 * counts.
 */

export const runImportSchema = z.object({
  body: z.object({
    sources: z
      .array(z.enum(IMPORT_SOURCES))
      .nonempty()
      .optional()
      .default([...IMPORT_SOURCES]),
    limit: z.coerce.number().int().min(1).max(100).optional().default(40),
  }),
});

/** POST /api/jobs/import */
export const runImport = asyncHandler(async (req, res) => {
  const { sources, limit } = req.validated.body;
  const result = await importJobs({ sources, limit });

  // A board being unreachable is reported, not thrown: the other source may
  // well have succeeded, and the caller needs to see which did what.
  const anyFailed = result.sources.some((s) => !s.ok);
  return ok(res, { ...result, partial: anyFailed });
});

/** GET /api/jobs/import/status */
export const getImportStatus = asyncHandler(async (req, res) => {
  return ok(res, await importStatus());
});
