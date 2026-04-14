*** Settings ***
Documentation       POC script to retrieve Gmail messages and log ALL multipart body parts.
...                 Demonstrates explicit iteration through every part of a multipart email,
...                 logging the index, content type, charset, and decoded payload for each.
Resource            common.resource
Resource            MultipartLogger.resource
Library             ImapLibrary2    #https://pypi.org/project/robotframework-imaplibrary2/

Suite Teardown      run keyword if    '${MAILBOX_OPEN}' == 'True'    Close Mailbox

*** Variables ***
${gmail-host-copado}            imap.gmail.com
${gmail-port-copado}            993
${gmail-user-copado}            copadopstester@gmail.com
${gmail-password-copado}        ${GoogleAppPass}
${timeout-copado}               60
${MAILBOX_OPEN}                 False

*** Test Cases ***
log-all-multipart-body-parts-copado
    [Documentation]    Waits for an unread email, walks the full multipart structure,
    ...                and explicitly logs EVERY part: index, content-type, charset,
    ...                and decoded payload. Designed for clear debugging visibility.
    [Tags]             gmail    multipart    logging    debug

    open-mailbox-copado
    ${email-index-copado}=      Wait For Email      timeout=${timeout-copado}
    Log To Console                       Email retrieved at index: ${email-index-copado}

    log-all-multipart-parts-copado    ${email-index-copado}

    Mark Email As Read          ${email-index-copado}
    close-mailbox-copado

log-multipart-parts-with-sender-filter-copado
    [Documentation]    Waits for an email from a specific sender, then logs all multipart parts.
    [Tags]             gmail    multipart    filter    logging

    open-mailbox-copado
    ${email-index-copado}=      Wait For Email
    ...                         sender=noreply@salesforce.com
    ...                         timeout=${timeout-copado}
    Log                         Filtered email retrieved at index: ${email-index-copado}

    log-all-multipart-parts-copado    ${email-index-copado}

    Mark Email As Read          ${email-index-copado}
    close-mailbox-copado
