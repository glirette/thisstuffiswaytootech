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

    def test_duplicate_members_retain_all_escaped_content(self):
        forbidden = r'"glirette\u002fexample-unpublished"'
        payloads = [
            '{"url":' + forbidden + ',"url":"public"}',
            '{"url":"public","url":' + forbidden + '}',
            '{"outer":{"url":' + forbidden + '},"outer":null}',
            '{"outer":null,"outer":[{"url":' + forbidden + '}]}',
            '{"url":' + forbidden + r',"\u0075rl":"public"}',
            '{' + forbidden + ':null,' + forbidden + ':"public"}',
            '[{"url":' + forbidden + ',"url":"public"}]',
        ]
        for payload in payloads:
            with self.subTest(payload=payload):
                self.assertCountEqual([
                    "source.JsOn: duplicate JSON member",
                    "source.JsOn: unexpected publisher-owned repository reference",
                ], check_text("source.JsOn", payload))

    def test_duplicate_members_are_explicit_even_without_a_reference(self):
        for payload in [
            '{"same":1,"same":2}',
            r'{"same":1,"\u0073ame":2}',
            '{"nested":[{"same":1,"same":2}]}',
            '{"same":1,"same":2,"child":{"same":3,"same":4}}',
        ]:
            with self.subTest(payload=payload):
                self.assertEqual(["source.json: duplicate JSON member"],
                                 check_text("source.json", payload))
        # Equal keys in distinct objects, case-distinct keys and arrays are valid.
        for payload in ['[{"same":1},{"same":2}]', '{"same":1,"Same":2}',
                        '[[],["same",1],["same",2],{}]']:
            with self.subTest(payload=payload):
                self.assertEqual([], check_text("source.json", payload))

    def test_overwritten_subtrees_still_receive_metadata_checks(self):
        payload = (r'{"outer":{"private\u0052evision":"synthetic"},'
                   r'"outer":{"document\u0047enerated":false},"outer":null}')
        self.assertCountEqual([
            "source.json: duplicate JSON member",
            "source.json: internal provenance or production metadata field",
            "source.json: internal provenance or production metadata field",
        ], check_text("source.json", payload))

    def test_unicode_escapes_at_every_allowed_name_position(self):
        for name in ["thisstuffiswaytootech", "NotaryGeekPublicKnowledgeWorker"]:
            for index, char in enumerate(name):
                escaped_name = name[:index] + f"\\u{ord(char):04x}" + name[index + 1:]
                reference = "https://github.com/glirette/" + escaped_name + "/pull/1"
                for payload in ['{"url":"' + reference + '"}',
                                '{"' + reference + '":"public"}',
                                '[{"nested":["' + reference + '"]}]']:
                    with self.subTest(name=name, index=index, payload=payload):
                        self.assertEqual([], check_text("source.JsOn", payload))

    def test_escaped_name_does_not_allow_unlisted_prefix_or_suffix(self):
        for name in [r'thisstuffiswaytoo\u0074ech-extra',
                     r'prefix-thisstuffiswaytoo\u0074ech',
                     r'example-\u0075npublished']:
            reference = "glirette/" + name
            for payload in ['{"url":"' + reference + '"}',
                            '{"' + reference + '":null}']:
                with self.subTest(payload=payload):
                    self.assertEqual([
                        "source.json: unexpected publisher-owned repository reference"
                    ], check_text("source.json", payload))

    def test_raw_fallback_and_two_pass_percent_detection_remain(self):
        reference = "glirette/" + "example-unpublished"
        for encoded in [reference, reference.replace("/", "%2F"),
                        reference.replace("/", "%252F")]:
            for path, text in [("source.md", encoded),
                               ("source.json", json.dumps({"url": encoded})),
                               ("source.JsOn", '{"url":"' + encoded + '"')]:
                with self.subTest(path=path, text=text):
                    findings = check_text(path, text)
                    self.assertIn(
                        f"{path}: unexpected publisher-owned repository reference",
                        findings,
                    )
                    if text.startswith('{"url":') and not text.endswith('}'):
                        self.assertIn(f"{path}: invalid JSON", findings)


if __name__ == "__main__":
    unittest.main()
