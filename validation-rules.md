# General File Validation Rules

Apply these six checks to any file type. Use the appropriate parser or inspection method for the file; do not assume a format-specific structure.

1. **Existence and readability** — Confirm the expected file exists, is accessible, and can be read without corruption or decoding errors.
2. **Format and structure** — Confirm the file matches its declared or expected format and that its structure can be parsed successfully.
3. **Required content** — Check that required fields, sections, records, or components are present and non-empty where required.
4. **Content validity** — Check values against applicable types, ranges, patterns, and domain rules; flag malformed or inconsistent data.
5. **Integrity and completeness** — Look for truncation, missing data, duplicate entries where uniqueness is expected, and internal inconsistencies.
6. **Safety and usability** — Check for unexpected executable content, embedded secrets or sensitive data, and whether the file can be safely consumed by its intended application.

Record each check as **pass**, **fail**, or **not applicable**, with a concise explanation for failures or exclusions. Do not report the file as valid if a required check fails.
