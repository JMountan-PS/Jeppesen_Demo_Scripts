*** Settings ***
Documentation       Reusable keywords for Gmail IMAP read + full multipart MIME parsing.
...                 Uses MailClientLibrary for IMAP access and a custom Python library
...                 (gmailMultipartWalker-copado.py) to walk nested MIME structures.
...
...                 MailClientLibrary docs: https://noubar.github.io/RobotFramework-MailClientLibrary/
...                 Python library path:    ../libraries/gmailMultipartWalker-copado.py
Resource            common.resource
Library             MailClientLibrary
Library             Collections
Library             Multipart_MailClient_Gmail.py

*** Variables ***
${imap-host-copado}     imap.gmail.com
${imap-port-copado}     993

*** Keywords ***
configure-imap-for-gmail-copado
    [Documentation]     Configures MailClientLibrary IMAP settings for Gmail.
    ...                 Credentials are injected via CRT Variable store (never hardcoded).
    [Tags]              gmail    imap    setup
    Set Imap Server Address             ${imap-host-copado}
    Set Imap Username And Password      ${GMAIL_ADDRESS}    ${APP_PASSWORD}
    Set Imap Ssl Port                   ${imap-port-copado}

read-and-log-all-parts-from-latest-email-copado
    [Documentation]     Reads the most recent email from the inbox via IMAP,
    ...                 then walks and logs every nested MIME part in full detail.
    ...                 Returns the list of parsed part dictionaries.
    [Tags]              gmail    imap    multipart    logging
    configure-imap-for-gmail-copado
    ${raw-mime-copado}=         Open Latest Imap Mail    useSsl=True
    Should Not Be Empty         ${raw-mime-copado}    No email found in inbox
    ${parts-copado}=            Log All Mime Parts Copado    ${raw-mime-copado}
    RETURN                      ${parts-copado}

read-and-log-all-parts-by-subject-copado
    [Documentation]     Fetches the first email matching the given subject,
    ...                 then walks and logs every nested MIME part.
    ...                 Returns the list of parsed part dictionaries.
    ...
    ...                 Argument:
    ...                   ${subject-copado} — subject line to match against
    [Tags]              gmail    imap    multipart    filter    logging
    [Arguments]         ${subject-copado}
    configure-imap-for-gmail-copado
    ${raw-mime-copado}=         Open Imap Mail By Subject    subject=${subject-copado}    useSsl=True
    Should Not Be Empty         ${raw-mime-copado}    No email found matching subject: ${subject-copado}
    ${parts-copado}=            log_all_mime_parts_copado    ${raw-mime-copado}
    RETURN                      ${parts-copado}

read-and-log-all-parts-by-sender-copado
    [Documentation]     Fetches the first email from the given sender address,
    ...                 then walks and logs every nested MIME part.
    ...                 Returns the list of parsed part dictionaries.
    ...
    ...                 Argument:
    ...                   ${sender-copado} — sender email address to filter by
    [Tags]              gmail    imap    multipart    filter    logging
    [Arguments]         ${sender-copado}
    configure-imap-for-gmail-copado
    ${raw-mime-copado}=         Open Imap Mail By Sender    sender=${sender-copado}    useSsl=True
    Should Not Be Empty         ${raw-mime-copado}    No email found from sender: ${sender-copado}
    ${parts-copado}=            Log All Mime Parts Copado    ${raw-mime-copado}
    RETURN                      ${parts-copado}

extract-plain-text-parts-copado
    [Documentation]     Filters a parsed parts list and returns only text/plain parts as a list.
    ...                 Call a read-and-log-all-parts-* keyword first to obtain the parts list.
    ...
    ...                 Argument:
    ...                   ${parts-copado} — list of part dicts from Log All Mime Parts Copado
    [Tags]              gmail    multipart    extract
    [Arguments]         ${parts-copado}
    ${text-parts-copado}=       Create List
    FOR    ${part}    IN    @{parts-copado}
        ${ct}=              Get From Dictionary    ${part}    content_type
        IF    '${ct}' == 'text/plain'
            Append To List      ${text-parts-copado}    ${part}
        END
    END
    RETURN    ${text-parts-copado}

extract-html-parts-copado
    [Documentation]     Filters a parsed parts list and returns only text/html parts as a list.
    ...                 Call a read-and-log-all-parts-* keyword first to obtain the parts list.
    ...
    ...                 Argument:
    ...                   ${parts-copado} — list of part dicts from Log All Mime Parts Copado
    [Tags]              gmail    multipart    extract
    [Arguments]         ${parts-copado}
    ${html-parts-copado}=       Create List
    FOR    ${part}    IN    @{parts-copado}
        ${ct}=              Get From Dictionary    ${part}    content_type
        IF    '${ct}' == 'text/html'
            Append To List      ${html-parts-copado}    ${part}
        END
    END
    RETURN    ${html-parts-copado}

assert-part-payload-contains-copado
    [Documentation]     Asserts that the payload of a specific part (by 1-based index)
    ...                 contains the expected text.
    ...                 part-index-copado is 1-based and matches the part_number field.
    ...
    ...                 Arguments:
    ...                   ${parts-copado}         — list of part dicts
    ...                   ${part-index-copado}    — 1-based part number to inspect
    ...                   ${expected-text-copado} — text that must appear in the payload
    [Tags]              gmail    multipart    assertion
    [Arguments]         ${parts-copado}    ${part-index-copado}    ${expected-text-copado}
    ${zero-index-copado}=       Evaluate    int(${part-index-copado}) - 1
    ${target-part-copado}=      Get From List    ${parts-copado}    ${zero-index-copado}
    ${payload-copado}=          Get From Dictionary    ${target-part-copado}    payload
    Should Contain              ${payload-copado}    ${expected-text-copado}

get-html-links-from-latest-email-copado
    [Documentation]     Reads the latest email and returns all <a href> links found
    ...                 in the text/html MIME part as a list of URL strings.
    ...                 Recommended method — HTML is always present in system emails.
    [Tags]              gmail    imap    links    html
    configure-imap-for-gmail-copado
    ${raw-mime-copado}=         Open Latest Imap Mail    useSsl=True
    Should Not Be Empty         ${raw-mime-copado}    No email found in inbox
    ${links-copado}=            Extract Links From Html Copado    ${raw-mime-copado}
    RETURN                      ${links-copado}

get-html-links-by-subject-copado
    [Documentation]     Reads the first email matching the given subject and returns
    ...                 all <a href> links from the HTML part as a list of URL strings.
    ...
    ...                 Argument:
    ...                   ${subject-copado} — subject line to match against
    [Tags]              gmail    imap    links    html    filter
    [Arguments]         ${subject-copado}
    configure-imap-for-gmail-copado
    ${raw-mime-copado}=         Open Imap Mail By Subject    subject=${subject-copado}    useSsl=True
    Should Not Be Empty         ${raw-mime-copado}    No email found matching subject: ${subject-copado}
    ${links-copado}=            Extract Links From Html Copado    ${raw-mime-copado}
    RETURN                      ${links-copado}

navigate-to-link-in-email-copado
    [Documentation]     High-level keyword: reads the latest email, extracts all HTML links,
    ...                 finds the first link containing the given substring, and navigates to it.
    ...                 Uses GoTo — assumes a browser is already open.
    ...
    ...                 Arguments:
    ...                   ${link-substring-copado} — partial URL text to match
    ...                                              e.g. 'salesforce.com', 'reset-password'
    [Tags]              gmail    imap    links    navigation
    [Arguments]         ${link-substring-copado}
    ${links-copado}=    get-html-links-from-latest-email-copado
    ${url-copado}=      Get Link Containing Copado    ${links-copado}    ${link-substring-copado}
    GoTo                ${url-copado}

navigate-to-link-in-email-by-subject-copado
    [Documentation]     High-level keyword: reads the email matching the given subject,
    ...                 extracts all HTML links, finds the first link containing the given
    ...                 substring, and navigates to it. Uses GoTo — assumes browser is open.
    ...
    ...                 Arguments:
    ...                   ${subject-copado}        — subject line to filter by
    ...                   ${link-substring-copado} — partial URL text to match
    [Tags]              gmail    imap    links    navigation    filter
    [Arguments]         ${subject-copado}    ${link-substring-copado}
    ${links-copado}=    get-html-links-by-subject-copado    ${subject-copado}
    ${url-copado}=      Get Link Containing Copado    ${links-copado}    ${link-substring-copado}
    GoTo                ${url-copado}
