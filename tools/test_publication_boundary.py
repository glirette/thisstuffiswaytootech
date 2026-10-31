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

    def test_json_escaped_owned_references_fail(self):
        payloads = [
            r'{"url":"https://github.com/glirette\/example-unpublished"}',
            r'{"url":"https://github.com/glirette\u002fexample-unpublished"}',
            r'{"glirette\u002fexample-unpublished":"synthetic"}',
            r'{"glirette\/example-unpublished":"synthetic"}',
            r'{"nested":[{"url":"GLIRETTE\u00252Fexample-unpublished"}]}',
            r'{"nested":[{"GLIRETTE\u0025252Fexample-unpublished":null}]}',
            r'"glirette\u002fexample-unpublished"',
            r'["glirette\u002fexample-unpublished"]',
        ]
        for payload in payloads:
            with self.subTest(payload=payload):
                json.loads(payload)
                self.assertEqual(
                    ["source.json: unexpected publisher-owned repository reference"],
                    check_text("source.json", payload),
                )

    def test_decoded_public_references_and_third_party_urls_remain_allowed(self):
        payloads = [
            r'{"url":"https://github.com/glirette\/NotaryGeekPublicKnowledgeWorker"}',
            r'{"GLIRETTE\u002fthisstuffiswaytootech":"public source"}',
            r'{"nested":["https://github.com/Azure\/azure-sdk-for-net"]}',
            r'{"url":"GLIRETTE\u0025252FNotaryGeekPublicKnowledgeWorker"}',
            r'"https://pages.nist.gov\/800-63-4/"',
        ]
        for payload in payloads:
            with self.subTest(payload=payload):
                self.assertEqual([], check_text("source.json", payload))

    def test_uppercase_json_extension_uses_all_json_checks(self):
        for payload in [
            r'{"url":"glirette\u002fexample-unpublished"}',
            '{"privateRevision": "synthetic"}',
            '{"documentGenerated": false}',
            '{',
        ]:
            with self.subTest(payload=payload):
                self.assertTrue(check_text("source.JSON", payload))
        self.assertEqual([], check_text("source.JSON", '{"publicOnly": true}'))


if __name__ == "__main__":
    unittest.main()
