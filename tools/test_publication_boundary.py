#!/usr/bin/env python3
"""Offline regression examples for public publication boundaries."""

import json
import unittest

from check_publication_boundary import check_text


class PublicationBoundaryTests(unittest.TestCase):
    def test_public_repository_and_artifact_provenance_remain_allowed(self):
        text = (
            "glirette/NotaryGeekPublicKnowledgeWorker public commit and payload hash; "
            "https://github.com/glirette/thisstuffiswaytootech/pull/1; "
            "https://github.com/Azure/azure-sdk-for-net"
        )
        self.assertEqual([], check_text("source.md", text))

    def test_unlisted_owned_reference_fails_in_prose_and_json(self):
        reference = "glirette/" + "example-unpublished"
        for path, text in [("source.md", reference),
                           ("source.json", json.dumps({"repository": reference}))]:
            with self.subTest(path=path):
                self.assertTrue(check_text(path, text))

    def test_case_and_encoded_slash_do_not_hide_owned_reference(self):
        reference = "GLIRETTE%2F" + "example-unpublished"
        self.assertTrue(check_text("source.md", reference))

    def test_nested_private_revision_metadata_fails_without_a_url(self):
        payload = {"canonicalEvidence": [{"privateAuthoredProvenance": {
            "commit": "0" * 40
        }}]}
        self.assertTrue(check_text("seed.json", json.dumps(payload)))

    def test_correspondence_production_state_is_not_public_evidence(self):
        payload = {"correspondence": {"productionState": {
            "documentGenerationQueued": False,
            "markdownSourcePrepared": True
        }}}
        self.assertTrue(check_text("evidence.json", json.dumps(payload)))

    def test_sourced_criticism_and_essential_limits_remain_allowed(self):
        payload = {
            "assessment": "The cited public representation is false.",
            "counterargument": "A private assessor report may exist.",
            "limitations": ["No completed transaction was inspected."],
            "sources": [{"url": "https://pages.nist.gov/800-63-4/"}]
        }
        self.assertEqual([], check_text("evidence.json", json.dumps(payload)))

    def test_malformed_json_fails(self):
        self.assertTrue(check_text("evidence.json", "{"))

    def test_existing_utf8_bom_is_accepted(self):
        self.assertEqual([], check_text("evidence.json", '\ufeff{"publicOnly": true}'))


if __name__ == "__main__":
    unittest.main()
