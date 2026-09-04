# Remote Manifest V1 — Draft Contract

Status: DESIGN / NOT IMPLEMENTED.

Required concepts:

\`\`\`json
{
  "schema_version": 1,
  "content_version": 1,
  "minimum_game_version": "TBD",
  "packs": [
    {
      "id": "pack_0001",
      "url": "relative-or-approved-url",
      "sha256": "hex",
      "levels": []
    }
  ],
  "disabled_levels": [],
  "scheduled_activations": []
}
\`\`\`

The final schema must be type-validated and versioned. Pack references must
be remotely verified before a production manifest activates them.

Rollback publishes a new auditable manifest version rather than silently
rewriting prior history.
