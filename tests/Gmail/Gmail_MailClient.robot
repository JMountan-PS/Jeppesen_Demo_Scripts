# =============================================================================
# Gmail READ + SEND using robotframework-mailclient
#
# Library:  MailClientLibrary (robotframework-mailclient)
# Install:  pip install robotframework-mailclient
# Docs:     https://noubar.github.io/RobotFramework-MailClientLibrary/
#
# All keywords validated against official keyword documentation:
#   https://noubar.github.io/RobotFramework-MailClientLibrary/
#
# Gmail requirements:
#   - IMAP must be enabled in Gmail Settings > See all settings > Forwarding
#     and POP/IMAP > Enable IMAP
#   - Use a Google App Password (not your account password):
#     myaccount.google.com/apppasswords
#   - IMAP host: imap.gmail.com  | SSL Port: 993
#   - SMTP host: smtp.gmail.com  | SSL Port: 465
# =============================================================================

*** Settings ***
Documentation       Gmail READ and SEND using robotframework-mailclient.
...                 Single library handles both IMAP (read) and SMTP (send).
...                 Ref: https://noubar.github.io/RobotFramework-MailClientLibrary/
Library             MailClientLibrary
Library             String

*** Variables ***
# -------------------------------------------------------
# Store credentials as CRT variables, never hardcoded.
# Pass via robot --variable flag or CRT Variable store.
# -------------------------------------------------------
${GMAIL_ADDRESS}        copadopstester@gmail.com
${APP_PASSWORD}         ${GoogleAppPass}
${RECIPIENT}            jmountan@copado.com

# Gmail server settings (validated against Google support)
${IMAP_HOST}            imap.gmail.com
${IMAP_SSL_PORT}        993
${SMTP_HOST}            smtp.gmail.com
${SMTP_SSL_PORT}        465

*** Test Cases ***

# =============================================================================
# SEND: Plain Text Email
# Keyword: Send Mail
# Ref: https://noubar.github.io/RobotFramework-MailClientLibrary/
# Arguments: senderMail, receiverMail, subject, text, useSsl
# =============================================================================
Send A Plain Text Email
    [Documentation]    Sends a plain text email via Gmail SMTP using SSL (port 465).
    ...                Uses: Set Smtp Server Address, Set Smtp Username And Password,
    ...                      Set Smtp Ssl Port, Send Mail
    [Tags]    send

    Configure SMTP For Gmail
    Send Mail
    ...    senderMail=${GMAIL_ADDRESS}
    ...    receiverMail=${RECIPIENT}
    ...    subject=Robot Framework Mail Test
    ...    text=This is a test email sent via robotframework-mailclient using Gmail SMTP.
    ...    useSsl=True
    Log    Email sent successfully to ${RECIPIENT}

# =============================================================================
# READ: Latest Email in Inbox
# Keyword: Open Latest Imap Mail
# Ref: https://noubar.github.io/RobotFramework-MailClientLibrary/
# Return: String — raw MIME content of the latest email
# =============================================================================
Read Latest Email
    [Documentation]    Reads and logs the raw MIME content of the most recent email.
    ...                Uses: Open Latest Imap Mail
    [Tags]    read

    Configure IMAP For Gmail
    ${mail_content}=    Open Latest Imap Mail    useSsl=True
    Log    Latest email content: ${mail_content}
    Should Not Be Empty    ${mail_content}    No email found in inbox

# =============================================================================
# READ: Email by Subject
# Keyword: Open Imap Mail By Subject
# Ref: https://noubar.github.io/RobotFramework-MailClientLibrary/
# Return: String — raw MIME content of first email matching subject
# =============================================================================
Read Email By Subject
    [Documentation]    Fetches the first email in the inbox matching a given subject.
    ...                Uses: Open Imap Mail By Subject
    [Tags]    read    filter

    Configure IMAP For Gmail
    ${mail_content}=    Open Imap Mail By Subject
    ...    subject=Robot Framework Mail Test
    ...    useSsl=True
    Log    Found email: ${mail_content}
    Should Contain    ${mail_content}    Robot Framework Mail Test

# =============================================================================
# READ: Email by Sender
# Keyword: Open Imap Mail By Sender
# Ref: https://noubar.github.io/RobotFramework-MailClientLibrary/
# Return: String — raw MIME content of first email matching sender address
# =============================================================================
Read Email By Sender
    [Documentation]    Fetches the first email from a specific sender address.
    ...                Uses: Open Imap Mail By Sender
    [Tags]    read    filter

    Configure IMAP For Gmail
    ${mail_content}=    Open Imap Mail By Sender
    ...    sender=${GMAIL_ADDRESS}
    ...    useSsl=True
    Log To Console    Email from sender: ${mail_content}
    Should Not Be Empty    ${mail_content}

# =============================================================================
# READ: Email Count
# Keyword: Get Imap Mail Count
# Ref: https://noubar.github.io/RobotFramework-MailClientLibrary/
# Return: Int — number of emails in the inbox
# =============================================================================
Get Email Count
    [Documentation]    Returns and logs the total number of emails in the inbox.
    ...                Uses: Get Imap Mail Count
    [Tags]    read    count

    Configure IMAP For Gmail
    ${count}=    Get Imap Mail Count    useSsl=True
    Log    Total emails in inbox: ${count}

# =============================================================================
# READ: Assert Inbox Is Empty
# Keyword: Imap Inbox Should Be Empty
# Ref: https://noubar.github.io/RobotFramework-MailClientLibrary/
# Fails if any email is found in the inbox
# =============================================================================
Assert Inbox Is Empty
    [Documentation]    Fails the test if any email is found in the inbox.
    ...                Useful for verifying a clean mailbox state before testing.
    ...                Uses: Imap Inbox Should Be Empty
    [Tags]    read    assertion

    Configure IMAP For Gmail
    Imap Inbox Should Be Empty    useSsl=True
    Log    Inbox is confirmed empty.

# =============================================================================
# END-TO-END: Send Then Read Back
# Combines SMTP send with IMAP read to verify round-trip delivery
# =============================================================================
Send And Verify Email Round Trip
    [Documentation]    Sends an email via SMTP, then reads it back via IMAP
    ...                to confirm successful delivery. Includes a wait for
    ...                delivery before reading.
    [Tags]    send    read    e2e

    # SEND
    Configure SMTP For Gmail
    Send Mail
    ...    senderMail=${GMAIL_ADDRESS}
    ...    receiverMail=${GMAIL_ADDRESS}
    ...    subject=Round Trip Test
    ...    text=Verifying end-to-end email delivery.
    ...    useSsl=True
    Log    Email sent. Waiting for delivery...

    # Brief wait for delivery
    Sleep    5s

    # READ BACK
    Configure IMAP For Gmail
    ${mail_content}=    Open Imap Mail By Subject
    ...    subject=Round Trip Test
    ...    useSsl=True
    Should Contain    ${mail_content}    Round Trip Test
    Log    Round-trip email delivery confirmed.

*** Keywords ***

# =============================================================================
# SMTP Configuration Keyword
# Ref: https://noubar.github.io/RobotFramework-MailClientLibrary/
# Set Smtp Server Address  → Sets SMTP host
# Set Smtp Username And Password → Sets SMTP credentials
# Set Smtp Ssl Port → Sets SSL port (465 for Gmail)
# =============================================================================
Configure SMTP For Gmail
    [Documentation]    Configures MailClientLibrary for Gmail SMTP.
    ...                All setter keywords validated from official library docs.
    Set Smtp Server Address             ${SMTP_HOST}
    Set Smtp Username And Password      ${GMAIL_ADDRESS}    ${GoogleAppPass}
    Set Smtp Ssl Port                   ${SMTP_SSL_PORT}

# =============================================================================
# IMAP Configuration Keyword
# Ref: https://noubar.github.io/RobotFramework-MailClientLibrary/
# Set Imap Server Address → Sets IMAP host
# Set Imap Username And Password → Sets IMAP credentials
# Set Imap Ssl Port → Sets SSL port (993 for Gmail)
# =============================================================================
Configure IMAP For Gmail
    [Documentation]    Configures MailClientLibrary for Gmail IMAP.
    ...                All setter keywords validated from official library docs.
    Set Imap Server Address             ${IMAP_HOST}
    Set Imap Username And Password      ${GMAIL_ADDRESS}    ${GoogleAppPass}
    Set Imap Ssl Port                   ${IMAP_SSL_PORT}
