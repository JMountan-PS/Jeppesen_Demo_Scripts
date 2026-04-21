*** Settings ***
Documentation              Walks and logs all nested MIME parts of Gmail emails using MailClientLibrary
...                        and a custom Python MIME parser (gmailMultipartWalker-copado.py).
...
...                        MailClientLibrary returns raw MIME strings from IMAP keywords.
...                        The custom Python library uses Python's built-in email module to walk
...                        the full nested MIME structure and expose each part as a dict.
...
...                        Credentials are passed via CRT Variable store — never hardcoded:
...                        GMAIL_ADDRESS               — Gmail address
...                        APP_PASSWORD                — Google App Password (injected as ${GoogleAppPass})
Resource                   Multipart_MailClient_Gmail.resource
Suite Setup                Open Browser                about:blank                 chrome

*** Variables ***
# Credentials injected via CRT Variable store — never hardcoded here.
${GMAIL_ADDRESS}           copadopstester@gmail.com
${APP_PASSWORD}            ${GoogleAppPass}
${Subject}                Fwd: Sandbox: Digital Aviation Success Team - Request Submission Acknowledgement 00531150 - Test CRT Product support case from portal

*** Test Cases ***
log-all-parts-of-latest-email-copado
    [Documentation]        Reads the most recent email from the Gmail inbox and logs
    ...                    every nested MIME part: part number, content-type, charset,
    ...                    container flag, and full decoded payload.
    [Tags]                 gmail                       multipart                   logging    debug
    ${parts}=              read-and-log-all-parts-from-latest-email-copado
    ${count}=              Get Length                  ${parts}
    Log                    Total parts parsed: ${count}

log-all-parts-by-subject-copado
    [Documentation]        Reads the first email matching a given subject and logs
    ...                    every nested MIME part in full detail.
    [Tags]                 gmail                       multipart                   filter     logging
    ${parts}=              read-and-log-all-parts-by-subject-copado
    ...                    subject-copado=${Subject}   
    ${count}=              Get Length                  ${parts}
    Log                    Total parts parsed: ${count}

log-all-parts-by-sender-copado
    [Documentation]        Reads the first email from a specific sender and logs
    ...                    every nested MIME part in full detail.
    [Tags]                 gmail                       multipart                   filter     logging
    ${parts}=              read-and-log-all-parts-by-sender-copado
    ...                    sender-copado=noreply@salesforce.com
    ${count}=              Get Length                  ${parts}
    Log                    Total parts parsed: ${count}

extract-and-verify-plain-text-content-copado
    [Documentation]        Reads the latest email, extracts only text/plain parts,
    ...                    and verifies the first plain-text part payload is not empty.
    [Tags]                 gmail                       multipart                   extract    assertion
    ${parts}=              read-and-log-all-parts-from-latest-email-copado
    ${text-parts}=         extract-plain-text-parts-copado                         ${parts}
    Should Not Be Empty    ${text-parts}               No text/plain parts found in email
    ${first-text-part}=    Get From List               ${text-parts}               0
    ${payload}=            Get From Dictionary         ${first-text-part}          payload
    Log                    Plain text payload: ${payload}
    Should Not Be Empty    ${payload}                  Plain text part payload is empty

extract-and-verify-html-content-copado
    [Documentation]        Reads the latest email, extracts only text/html parts,
    ...                    and logs the raw HTML payload of the first HTML part.
    [Tags]                 gmail                       multipart                   extract    html
    ${parts}=              read-and-log-all-parts-from-latest-email-copado
    ${html-parts}=         extract-html-parts-copado                               ${parts}
    Should Not Be Empty    ${html-parts}               No text/html parts found in email
    ${first-html-part}=    Get From List               ${html-parts}               0
    ${payload}=            Get From Dictionary         ${first-html-part}          payload
    Log                    HTML payload: ${payload}
    Should Not Be Empty    ${payload}                  HTML part payload is empty




# ---------------------------------------------------------------------------
# Link extraction test cases
# ---------------------------------------------------------------------------

log-all-html-links-from-latest-email-copado
    [Documentation]     Reads the latest email, extracts all <a href> links from
    ...                 the HTML part, and logs them. Use this to discover what links
    ...                 are present before writing targeted navigation test cases.
    [Tags]              gmail    links    html    debug
    ${links}=           get-html-links-from-latest-email-copado
    ${count}=           Get Length    ${links}
    Log                 Total HTML links found: ${count}
    Log Many            @{links}

navigate-to-first-link-in-email-copado
    [Documentation]     Reads the latest email, extracts the first HTML link by index,
    ...                 and navigates to it. Use get-html-links-from-latest-email-copado
    ...                 first (debug case above) to confirm the correct index.
    [Tags]              gmail    links    navigation
    ${links}=           get-html-links-from-latest-email-copado
    Should Not Be Empty     ${links}    No links found in email HTML part
    ${url}=             Get Link By Index Copado    ${links}    1
    GoTo                ${url}

navigate-to-salesforce-link-in-email-copado
    [Documentation]     Reads the latest email, finds the first link containing
    ...                 'salesforce.com', and navigates to it.
    ...                 Practical pattern for Salesforce notification emails.
    [Tags]              gmail    links    navigation    salesforce
    navigate-to-link-in-email-copado    salesforce.com

navigate-to-link-by-subject-and-keyword-copado
    [Documentation]     Reads the email matching the given subject, finds the first link
    ...                 containing the given substring, and navigates to it.
    ...                 Most targeted and reliable navigation pattern.
    [Tags]              gmail    links    navigation    filter
    navigate-to-link-in-email-by-subject-copado
    ...    subject-copado=${Subject}
    ...    link-substring-copado=3A__flightpath-2D-2Dqa1.sandbox.my.site.com

navigate-to-nth-link-by-subject-copado
    [Documentation]     Reads the email matching the given subject, extracts all HTML links,
    ...                 and navigates to the link at a specific 1-based index.
    ...                 Use log-all-html-links-from-latest-email-copado first to confirm index.
    [Tags]              gmail    links    navigation    filter
    ${links}=           get-html-links-by-subject-copado
    ...                 subject-copado=Robot Framework Mail Test
    Should Not Be Empty     ${links}    No links found in email
    ${url}=             Get Link By Index Copado    ${links}    2
    GoTo                ${url}
