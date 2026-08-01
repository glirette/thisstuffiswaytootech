# Twilio And xAI Telecom Deployment Source Trail

Captured: 2026-07-31

## Purpose

Public-safe source trail for building repeatable phone-number deployments with Twilio and xAI Voice. It separates documented provider behavior from implementation choices that still require account-specific validation.

This note contains no private phone numbers, provider identifiers, credentials, customer data, prompts, transfer destinations, or production topology.

## Controlling Official Sources

- xAI SIP Phone Calls: https://docs.x.ai/developers/model-capabilities/audio/speech-to-speech/sip
- xAI Voice overview: https://docs.x.ai/developers/model-capabilities/audio/voice-agent
- Twilio Elastic SIP Trunking: https://www.twilio.com/docs/sip-trunking
- Twilio SIP trunk troubleshooting: https://www.twilio.com/docs/sip-trunking/troubleshooting
- Twilio SIP trunk scale and limits: https://www.twilio.com/docs/sip-trunking/scale-and-limits
- Twilio Messaging Services: https://www.twilio.com/docs/messaging/services
- Twilio A2P 10DLC onboarding: https://www.twilio.com/docs/messaging/compliance/a2p-10dlc/direct-standard-onboarding
- Twilio WhatsApp sender registration: https://www.twilio.com/docs/whatsapp/register-senders-using-api

Recheck current documentation before an operational change. Console options, API fields, limits, pricing, and provider behavior can change.

## Three Independent Planes

A phone number may support several channels, but the configuration planes are independent:

| Plane | Typical routing objects | Independent checks |
| --- | --- | --- |
| Voice | Incoming number, Elastic SIP trunk, origination URI, voice agent | Answer path, SIP identity, audio, transfer, fallback |
| SMS/MMS | Messaging Service, A2P campaign, sender, webhook | Consent, campaign state, delivery, opt-out, inbound handling |
| WhatsApp | Registered sender, business profile, templates, webhook | Sender approval, template state, inbound and outbound handling |

Do not infer messaging behavior from a voice route or voice behavior from Messaging Service membership. A change ticket should name the exact plane and assert that the others remain unchanged.

## Number-Specific xAI Routing

xAI documents Direct SIP registration per phone number. The carrier or PBX sends calls to:

```text
sip:{registered-number}@sip.voice.x.ai;transport=tls
```

The number in the SIP request URI should identify the Direct SIP registration and intended agent for that call.

## Twilio Origination Behavior

Twilio documents two materially different origination-URI forms.

Host-only form:

```text
sip:voice-provider.example;transport=tls
```

When the user part is omitted, Twilio inserts the Twilio DID that received the PSTN call. A call to a synthetic number such as `+15551234567` is sent as:

```text
sip:+15551234567@voice-provider.example;transport=tls
```

Fixed-user form:

```text
sip:fixed-route@voice-provider.example;transport=tls
```

Twilio reuses that fixed user part for every DID attached to the trunk. The actual dialed DID is still conveyed in the SIP `Diversion` header, but the request URI no longer identifies it directly.

## Shared Lab-Number Anti-Pattern

A common pilot sequence can create an accidental dependency:

1. Configure the first lab DID as a fixed SIP user part.
2. Validate the lab call.
3. Attach more DIDs to the same trunk because it already works.
4. Observe every SIP `To` value showing the lab identity.

The carrier is behaving correctly: the configuration instructed it to reuse the fixed user part. The lab DID has become an internal routing anchor even though it is not the public or primary number.

A shared trunk can be useful. A shared phone-number identity is usually unnecessary and makes diagnostics, ownership, and future migration harder.

## Candidate Scalable Pattern

The following composition is consistent with the two providers' published behavior:

1. Register every DID individually with xAI Direct SIP.
2. Assign each registration to its intended agent.
3. Configure one Twilio trunk with a host-only xAI origination URI:

```text
sip:sip.voice.x.ai;transport=tls
```

4. Attach only DIDs that have matching xAI registrations.
5. Let Twilio insert the actual called DID as the SIP user part.

This should produce the number-specific URI xAI documents while retaining one scalable trunk. It is an inference from the combination of official provider documentation, not an explicit xAI statement about this exact shared-trunk composition. Validate it with an unused nonmatching canary before calling it supported in a specific account.

Do not use the original fixed-user DID as the first canary. Both the old and new routes would produce the same user part and therefore would not prove dynamic substitution.

## Conservative Fallback Pattern

If the shared host-only pattern fails provider validation, use one isolated Twilio trunk or routing unit per DID, each pointing at that DID's exact xAI URI.

This is easier to reason about but creates more provider objects and scales less efficiently. Application-level TwiML routing is another option, but it introduces application availability, additional call legs, and transfer behavior that must be tested separately.

## Public-Safe Inventory Template

Maintain a private record per DID with these categories; publish only placeholders or redacted summaries:

- provider account or subaccount and environment;
- business/client owner and operator;
- E.164 number, market, number type, acquisition date, and current cost;
- lifecycle status such as `hold`, `lab`, `publish`, `quarantine`, or `release-review`;
- voice trunk, origination mode, registered voice provider number, agent, and transfer role;
- SMS/MMS Messaging Service, A2P campaign, sender role, webhook, and consent path;
- WhatsApp sender and webhook role;
- public listings, printed use, stored-customer use, and porting history;
- metadata-only traffic windows and most recent activity;
- recording, retention, compliance, and emergency-address state where applicable;
- rollback evidence, acceptance date, and release-review decision.

Use labels and environment-safe references in public material. Keep credentials, SIDs, full private inventories, raw call records, caller identities, and customer data in an approved private store.

## Deployment Sequence

1. Define the DID's owner, purpose, environment, channels, agent, and rollback owner.
2. Snapshot the existing voice and messaging configuration privately.
3. Register the exact DID with xAI and assign it to the intended agent.
4. Confirm the agent's model, voice, greeting, interruption, tools, transfer policy, connectors, files, and retention posture.
5. Attach one unused nonmatching canary DID to the candidate host-only trunk.
6. Place a controlled inbound call and inspect the resulting SIP identity and agent selection.
7. Move production DIDs one at a time, validating each before the next.
8. Preserve the previous route through an observation window.
9. Treat SMS/A2P and WhatsApp as unchanged unless their own reviewed change is in scope.

## Acceptance Evidence

For each controlled call, verify:

- the incoming-number field identifies the dialed DID;
- the SIP request `To` user part contains that same DID;
- the SIP `Diversion` header agrees when inspected;
- the intended provider registration and agent answer;
- stable two-way audio and caller interruption;
- hangup and transfer behavior where configured; and
- unchanged SMS/A2P and WhatsApp state.

Correlate parent and child call identifiers privately, particularly when transfers create another leg. Do not publish caller numbers, call identifiers, recordings, transcripts, or account identifiers.

## Diagnostics

| Symptom | First checks |
| --- | --- |
| Every SIP `To` shows one DID | Look for a fixed user part in the shared Twilio origination URI |
| Correct incoming DID, wrong agent | Compare SIP `To` with the voice provider's registered DID and agent assignment |
| Greeting only or silence | Check model/session behavior, media negotiation, and provider call events separately |
| One-way audio | Inspect RTP destination, NAT behavior, codecs, TLS/SRTP posture, and packet counters |
| Transfer fails | Inspect SIP REFER settings, transfer target, child leg, status code, and post-answer media |
| Logs disagree about entry number | Prefer the incoming-number resource and `Called Via`; then reconcile SIP `To` and `Diversion` |

Do not compensate for a transport or topology error by making the conversational prompt more complex.

## Rollback

Rollback should be per DID:

1. Reattach only the affected DID to its preserved previous voice route.
2. Re-query the number and compare it with the private snapshot.
3. Confirm messaging and WhatsApp fingerprints did not change.
4. Place one controlled inbound call.
5. Record a redacted failure category and next action.

Do not delete the prior route during initial acceptance. Do not treat a previously used provider as a safe fallback without current validation.

## Client Isolation

For third-party deployments, prefer separate provider accounts or subaccounts and separate AI teams/environments where practical. At minimum, isolate trunks, agents, transfer destinations, credentials, logs, billing ownership, retention policy, and rollback artifacts by client and environment.

A reusable runbook should describe provider-neutral invariants first and put client-specific identifiers, URLs, prompts, and secrets in private configuration records.

## Number Lifecycle

Low-cost DIDs can have option value as labs, geographic entry points, vanity numbers, quarantined legacy lines, or future service channels. Releasing a number is destructive because it can be reassigned.

Before release, confirm no voice, messaging, WhatsApp, verification, emergency, public listing, printed, stored-customer, vanity, geographic, lab, or failover dependency remains. Use a cooling-off period after detachment and require explicit approval naming the exact DID. Zero recent traffic alone is not sufficient evidence.

## What The Sources Do Not Prove

- They do not prove a private account has the required entitlements or correct configuration.
- They do not prove the shared host-only Twilio/xAI composition works until a controlled nonmatching DID passes.
- They do not prove transfers, audio, retention, recording, or agent behavior are acceptable.
- They do not authorize live routing, outbound calls or messages, customer-data access, or number release.
- They do not replace account-specific snapshots, controlled testing, monitoring, and rollback.
