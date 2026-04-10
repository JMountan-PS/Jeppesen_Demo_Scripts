*** Settings ***
Documentation       Reusable keywords for Gmail IMAP multipart email logging.
...                 Provides full visibility into every body part of a multipart email.
Resource            common.resource
Library             ImapLibrary2    #https://pypi.org/project/robotframework-imaplibrary2/
Library             String
Library             Collections

*** Variables ***
${gmail-host-copado}        imap.gmail.com
${gmail-port-copado}        993

*** Keywords ***
open-mailbox-copado
    [Documentation]     Opens the Gmail IMAP mailbox using injected credentials.
    ...                 Sets the MAILBOX_OPEN suite variable to enable safe teardown.
    [Tags]              gmail    setup    imap
    Open Mailbox
    ...                 host=${gmail-host-copado}
    ...                 user=${gmail-user-copado}
    ...                 password=${gmail-password-copado}
    ...                 port=${gmail-port-copado}
    Set Suite Variable  ${MAILBOX_OPEN}    True

close-mailbox-copado
    [Documentation]     Closes the Gmail IMAP mailbox and resets the open-state flag.
    [Tags]              gmail    teardown    imap
    Close Mailbox
    Set Suite Variable  ${MAILBOX_OPEN}    False

log-all-multipart-parts-copado
    [Documentation]     Walks the full MIME multipart structure of the given email and
    ...                 logs every part in detail:
    ...                   - Part index (1-based, human readable)
    ...                   - Content-Type  (e.g. text/plain, text/html, image/png)
    ...                   - Charset       (encoding declared by the sender)
    ...                   - Decoded payload (the actual body content)
    ...
    ...                 How it works:
    ...                   Walk Multipart Email resets the internal MIME iterator to the
    ...                   first part and returns the TOTAL number of parts as an integer.
    ...                   Each subsequent call to Walk Multipart Email advances the
    ...                   iterator by one part. Get Multipart Content Type and
    ...                   Get Multipart Payload then operate on the CURRENT part.
    [Tags]              gmail    multipart    logging    debug
    [Arguments]         ${email-index-copado}

    # ── Step 1: Initialise the walker and get total part count ──────────────────
    ${part-count-copado}=       Walk Multipart Email    ${email-index-copado}
    Log                         ═══════════════════════════════════════════════════
    Log                         📧 EMAIL MULTIPART INSPECTION STARTED
    Log                         Total MIME parts found: ${part-count-copado}
    Log                         ═══════════════════════════════════════════════════

    # ── Step 2: Log top-level headers (available after the first Walk call) ─────
    ${subject-copado}=          Get Multipart Field     Subject
    ${from-copado}=             Get Multipart Field     From
    ${to-copado}=               Get Multipart Field     To
    ${date-copado}=             Get Multipart Field     Date
    Log                         ── HEADERS ──────────────────────────────────────
    Log                         Subject : ${subject-copado}
    Log                         From    : ${from-copado}
    Log                         To      : ${to-copado}
    Log                         Date    : ${date-copado}
    Log                         ─────────────────────────────────────────────────

    # ── Step 3: Iterate through every part and log its details ─────────────────
    #   NOTE: Walk Multipart Email was already called once above (part 1 is current).
    #   We handle part 1 first, then loop for parts 2..N.
    log-single-part-copado      1    ${part-count-copado}

    ${remaining-parts-copado}=  Evaluate    int(${part-count-copado}) - 1
    FOR    ${i}    IN RANGE    ${remaining-parts-copado}
        # Advance the iterator to the next part
        Walk Multipart Email    ${email-index-copado}
        # Human-readable part number is i+2 (since part 1 was handled before the loop)
        ${part-number-copado}=  Evaluate    ${i} + 2
        log-single-part-copado  ${part-number-copado}    ${part-count-copado}
    END

    Log                         ═══════════════════════════════════════════════════
    Log                         ✅ EMAIL MULTIPART INSPECTION COMPLETE
    Log                         ═══════════════════════════════════════════════════

log-single-part-copado
    [Documentation]     Logs the content-type, charset, and decoded payload of whichever
    ...                 MIME part is currently active in the Walk Multipart iterator.
    ...                 Call Walk Multipart Email before this keyword to advance the cursor.
    [Tags]              gmail    multipart    logging
    [Arguments]         ${part-number-copado}    ${total-parts-copado}

    # Read current part metadata
    ${content-type-copado}=     Get Multipart Content Type
    ${charset-copado}=          Get Multipart Field         charset
    ${payload-copado}=          Get Multipart Payload       decode=True

    Log                         ── PART ${part-number-copado} of ${total-parts-copado} ──────────────────────────
    Log                         Content-Type : ${content-type-copado}
    Log                         Charset      : ${charset-copado}

    # ── Payload logging strategy per content type ───────────────────────────────
    IF    '${content-type-copado}' == 'text/plain'
        Log                     ▶ PLAIN TEXT BODY:
        Log                     ${payload-copado}

    ELSE IF    '${content-type-copado}' == 'text/html'
        Log                     ▶ HTML BODY (raw markup):
        Log                     ${payload-copado}
        # Optionally strip tags for a readable preview
        ${plain-preview-copado}=    Replace String Using Regexp
        ...                         ${payload-copado}
        ...                         <[^>]+>
        ...                         ${EMPTY}
        ${plain-preview-copado}=    Strip String    ${plain-preview-copado}
        Log                     ▶ HTML BODY (tags stripped, preview):
        Log                     ${plain-preview-copado}

    ELSE IF    '${content-type-copado}' == 'multipart/alternative'
        Log                     ▶ CONTAINER PART (multipart/alternative) — no direct payload, sub-parts follow.

    ELSE IF    '${content-type-copado}' == 'multipart/mixed'
        Log                     ▶ CONTAINER PART (multipart/mixed) — no direct payload, sub-parts follow.

    ELSE
        # Catch-all: binary attachments, images, calendar invites, etc.
        Log                     ▶ NON-TEXT PART (${content-type-copado}) — payload logged as-is (may be binary/base64):
        Log                     ${payload-copado}
    END

    Log            
