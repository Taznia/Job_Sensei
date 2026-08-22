# CSE471 — API Postman Collection

**Project:** Job Sensei · **Group:** 8 · **Section:** 02
**Submitted by:** Adreed Saadad Hasan · **ID:** 22301190
**Backend Framework:** Node.js + Express + MongoDB Atlas
**Server port:** `1190` (last four digits of the student ID)

**Feature 1 — Career Profile** (Module 1)
**Feature 2 — Job Search** (Module 3)

Base URL for every endpoint below: `http://127.0.0.1:1190/api`

---

## Running it

```
cd backend
npm install
```

Create `backend/.env`:

```
PORT=1190
MONGODB_URI=<your MongoDB Atlas connection string>
JWT_SECRET=<any long random string>
```

Then seed the database once and start the server:

```
npm run seed
npm start
```

Import `backend/postman/JobSensei_Adreed_22301190.postman_collection.json` into
Postman. Run **Setup → Login** first; it stores the JWT in the `{{token}}`
collection variable that every Career Profile request sends.

Seeded login: `demo@jobsensei.app` / `Demo123!`

---

# Feature 1 — Career Profile (Module 1)

Stores the complete career profile for a job seeker: education, work
experience, preferred job roles, location, expected salary, skills,
certifications, portfolio links, and career goals.

Every route acts on the authenticated user's **own** profile, so no user id
appears in the path — one user cannot read or edit another's career record.

Code: `backend/src/controllers/careerProfile.controller.js`,
`backend/src/models/CareerProfile.js`,
`backend/src/utils/profileCompleteness.js`

---

## API 1.1 — Get my career profile

- **Endpoint URL:** `http://127.0.0.1:1190/api/career-profile/me`
- **HTTP Method:** GET
- **Headers:** `Authorization: Bearer <token>`
- **Body:** None

Returns the full profile plus a computed completeness score. Creates the
profile from the existing user record on first call, so a new account never
404s here.

```js
export const getMyProfile = asyncHandler(async (req, res) => {
  const profile = await loadOrCreateProfile(req.user);
  return ok(res, serialize(profile));
});
```

---

## API 1.2 — Update profile basics

- **Endpoint URL:** `http://127.0.0.1:1190/api/career-profile/me`
- **HTTP Method:** PUT
- **Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`
- **Body:**

```json
{
  "fullName": "Adreed Saadad Hasan",
  "headline": "Flutter Developer • Building for mobile-first teams",
  "location": "Dhaka, Bangladesh",
  "phone": "+880 1712 345678",
  "about": "Mobile engineer with a product mindset.",
  "careerGoals": "Move into a senior mobile role within two years."
}
```

All fields optional. Send an optional field as `null` to clear it; `fullName`
and `email` cannot be emptied.

```js
export const updateBasics = asyncHandler(async (req, res) => {
  const body = req.validated.body;
  if (Object.keys(body).length === 0) {
    throw new HttpError(400, 'Request body is empty.');
  }
  const profile = await loadOrCreateProfile(req.user);
  for (const [field, value] of Object.entries(body)) {
    profile[field] = value === '' ? null : value;
  }
  await profile.save();
  return ok(res, serialize(profile));
});
```

---

## API 1.3 — Update job preferences

- **Endpoint URL:** `http://127.0.0.1:1190/api/career-profile/me/preferences`
- **HTTP Method:** PUT
- **Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`
- **Body:**

```json
{
  "preferredRoles": ["Flutter Developer", "Mobile Engineer"],
  "preferredLocations": ["Dhaka", "Remote"],
  "workModes": ["hybrid", "remote"],
  "employmentTypes": ["full-time", "contract"],
  "salary": { "min": 70000, "max": 110000, "currency": "BDT", "period": "monthly" },
  "openToRelocation": true,
  "availableFrom": "2026-09-01"
}
```

Replaced wholesale rather than merged, because the form always submits the
object complete — a partial merge would make removing a role impossible.
Returns 400 if `salary.max` is below `salary.min`.

```js
profile.preferences = {
  preferredRoles: body.preferredRoles,
  preferredLocations: body.preferredLocations,
  workModes: body.workModes,
  employmentTypes: body.employmentTypes,
  salary: body.salary ?? null,
  openToRelocation: body.openToRelocation,
  availableFrom: body.availableFrom ?? null,
};
await profile.save();
```

---

## API 1.4 — Add a section entry

- **Endpoint URL:** `http://127.0.0.1:1190/api/career-profile/me/sections/education`
- **HTTP Method:** POST
- **Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`
- **Body:**

```json
{
  "institution": "BRAC University",
  "degree": "BSc",
  "fieldOfStudy": "Computer Science and Engineering",
  "startDate": "2022-01-01",
  "endDate": "2026-06-30",
  "grade": "CGPA 3.72 / 4.00"
}
```

**Path parameter** `:section` accepts `education`, `experience`, `skills`,
`certifications`, or `portfolio-links`. One route serves all five sections;
each has its own validation shape. Returns **201** with the created entry
(including its `_id`) and the recalculated completeness.

```js
export const addSectionEntry = asyncHandler(async (req, res) => {
  const { section } = req.validated.params;
  const field = SECTION_FIELDS[section];
  const entry = parseSectionBody(section, req.body, { partial: false });

  const profile = await loadOrCreateProfile(req.user);
  profile[field].push(entry);
  await profile.save();

  const saved = profile[field][profile[field].length - 1];
  return created(res, {
    entry: saved,
    completeness: computeCompleteness(profile.toObject()),
  });
});
```

---

## API 1.5 — Update a section entry

- **Endpoint URL:** `http://127.0.0.1:1190/api/career-profile/me/sections/education/<entryId>`
- **HTTP Method:** PUT
- **Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`
- **Body:**

```json
{
  "grade": "CGPA 3.85 / 4.00",
  "isCurrent": true,
  "endDate": null
}
```

Partial update — send only the changed fields. `entryId` is the `_id` returned
by API 1.4. Marking an entry current clears its end date, which is why
`endDate` is nullable.

```js
const entry = profile[field].id(entryId);
if (!entry) throw new HttpError(404, `No ${section} entry with id ${entryId}.`);
entry.set(patch);
await profile.save();
```

---

## API 1.6 — Delete a section entry

- **Endpoint URL:** `http://127.0.0.1:1190/api/career-profile/me/sections/education/<entryId>`
- **HTTP Method:** DELETE
- **Headers:** `Authorization: Bearer <token>`
- **Body:** None

Returns the removed id, the remaining count in that section, and the
recalculated completeness. 404s on an id not present in this profile.

```js
entry.deleteOne();
await profile.save();
return ok(res, {
  deleted: true,
  removedId: entryId,
  remaining: profile[field].length,
  completeness: computeCompleteness(profile.toObject()),
});
```

---

## API 1.7 — Get profile completeness

- **Endpoint URL:** `http://127.0.0.1:1190/api/career-profile/me/completeness`
- **HTTP Method:** GET
- **Headers:** `Authorization: Bearer <token>`
- **Body:** None

Weighted score out of 100 plus the still-empty sections, ordered by how much
each would improve job matching. Skills and job preferences carry 20 each
because the matcher reads them directly; portfolio links carry 5.

```js
export function computeCompleteness(profile) {
  let percent = 0;
  const missing = [];
  for (const [section, weight] of Object.entries(COMPLETENESS_WEIGHTS)) {
    if (filled[section]) percent += weight;
    else missing.push(section);
  }
  missing.sort((a, b) => COMPLETENESS_WEIGHTS[b] - COMPLETENESS_WEIGHTS[a]);
  return { percent, missing, isComplete: missing.length === 0 };
}
```

---

# Feature 2 — Job Search (Module 3)

A searchable job list filtered by title, company, skill, location, salary
range, job type, experience level, and remote or on-site preference, showing
the most relevant results first.

Code: `backend/src/controllers/jobSearch.controller.js`

---

## API 2.1 — Search jobs

- **Endpoint URL:** `http://127.0.0.1:1190/api/jobs/search?q=frontend&page=1&limit=10`
- **HTTP Method:** GET
- **Headers:** None required. `Authorization: Bearer <token>` is optional — when
  present, each result carries `isSaved` for that user.
- **Body:** None (all input is query parameters)

| Parameter | Values | Meaning |
|---|---|---|
| `q` | text | Full-text search over title, company, description |
| `company` | text | Case-insensitive partial match |
| `location` | text | Case-insensitive partial match |
| `skill` | `React,TypeScript` | Comma-separated; matches any |
| `type` | `full-time` `part-time` `contract` `internship` | Job type |
| `workMode` | `onsite` `remote` `hybrid` | Working arrangement |
| `experienceLevel` | `entry` `junior` `mid` `senior` `lead` | Seniority |
| `salaryMin` | number | Job's upper bound must clear this |
| `salaryMax` | number | Job's lower bound must not exceed this |
| `remote` | `true` `false` | Shorthand for `workMode=remote` |
| `sort` | `relevance` `newest` `salary` `title` | Default: relevance with `q`, else newest |
| `page` | number ≥ 1 | Default 1 |
| `limit` | 1–50 | Default 10 |

Two decisions worth noting. Salary matches on **overlap**: a 90k–140k job still
appears for `salaryMin=100000`, because it can pay that. And relevance sorting
only applies when `q` is present — with filters alone every document scores the
same, so newest-first is the honest default.

```js
export const searchJobs = asyncHandler(async (req, res) => {
  const query = req.validated.query;
  const filter = buildFilter(query);
  const { sort, projection } = buildSort(query.sort, Boolean(filter.$text));

  const [jobs, total] = await Promise.all([
    Job.find(filter, projection)
      .sort(sort)
      .skip((query.page - 1) * query.limit)
      .limit(query.limit)
      .lean(),
    Job.countDocuments(filter),
  ]);

  const savedIds = req.user?.savedJobs || [];
  return ok(res, {
    total,
    page: query.page,
    limit: query.limit,
    pages: Math.max(1, Math.ceil(total / query.limit)),
    sort: query.sort || (filter.$text ? 'relevance' : 'newest'),
    items: jobs.map((job) => serialize(job, savedIds)),
  });
});
```

---

## API 2.2 — Get filter options

- **Endpoint URL:** `http://127.0.0.1:1190/api/jobs/search/filters`
- **HTTP Method:** GET
- **Headers:** None
- **Body:** None

Returns the distinct companies, locations and skills actually present in open
jobs, the enum lists for type / work mode / experience level / sort, and the
real salary floor and ceiling. Feeds the filter sheet so it only ever offers
values that match something.

```js
const [companies, locations, skills, salary] = await Promise.all([
  Job.distinct('company', { status: 'open' }),
  Job.distinct('location', { status: 'open' }),
  Job.distinct('skills', { status: 'open' }),
  Job.aggregate([
    { $match: { status: 'open', salaryMin: { $ne: null } } },
    { $group: { _id: null, min: { $min: '$salaryMin' }, max: { $max: '$salaryMax' } } },
  ]),
]);
```

---

## Endpoint summary

| # | Method | Endpoint | Auth |
|---|---|---|---|
| 1.1 | GET | `/api/career-profile/me` | Bearer |
| 1.2 | PUT | `/api/career-profile/me` | Bearer |
| 1.3 | PUT | `/api/career-profile/me/preferences` | Bearer |
| 1.4 | POST | `/api/career-profile/me/sections/:section` | Bearer |
| 1.5 | PUT | `/api/career-profile/me/sections/:section/:entryId` | Bearer |
| 1.6 | DELETE | `/api/career-profile/me/sections/:section/:entryId` | Bearer |
| 1.7 | GET | `/api/career-profile/me/completeness` | Bearer |
| 2.1 | GET | `/api/jobs/search` | Optional |
| 2.2 | GET | `/api/jobs/search/filters` | None |
