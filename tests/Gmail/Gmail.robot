*** Settings ***
Documentation    POC script to retrieve Gmail messages using Robot Framework
...              This script demonstrates how to connect to Gmail via IMAP and retrieve messages
Library          ImapLibrary2    #https://pypi.org/project/robotframework-imaplibrary2/
Library          Collections
Library          String

*** Variables ***
${GMAIL_HOST}         imap.gmail.com
${GMAIL_PORT}         993
${GMAIL_USER}         copadopstester@gmail.com
${GMAIL_PASSWORD}     ${GoogleAppPass}
${SENDER_FILTER}      noreply@salesforce.com
${TIMEOUT}            60

*** Test Cases ***
Retrieve Latest Email - Simple Approach
    [Documentation]    Waits for a single email and retrieves its body
    [Tags]    verified    simple
    
    # Open connection
    Open Mailbox    host=${GMAIL_HOST}    user=${GMAIL_USER}    password=${GMAIL_PASSWORD}    port=${GMAIL_PORT}
    
    # Wait for any unread email (returns email index/UID)
    ${email_index}=    Wait For Email    timeout=${TIMEOUT}
    Log    Email index: ${email_index}
    
    # Get email body directly (works for non-multipart emails)
    ${body}=    Get Email Body    ${email_index}
    Log    Email body: ${body}
    
    # Verify content
    Should Contain    ${body}    expected text
    
    # Mark as read and close
    Mark Email As Read    ${email_index}
    Close Mailbox

Retrieve Latest Email From Specific Sender
    [Documentation]    Waits for email from specific sender
    [Tags]    verified    filter
    
    Open Mailbox    host=${GMAIL_HOST}    user=${GMAIL_USER}    password=${GMAIL_PASSWORD}
    
    # Wait for email from specific sender
    ${email_index}=    Wait For Email    sender=noreply@example.com    timeout=${TIMEOUT}
    
    # Get body
    ${body}=    Get Email Body    ${email_index}
    Log    Body: ${body}
    
    Close Mailbox

Retrieve ALL Unread Emails
    [Documentation]    Simple way to get all unread emails using status filter
    [Tags]    verified    multiple
    
    Open Mailbox    host=${GMAIL_HOST}    user=${GMAIL_USER}    password=${GMAIL_PASSWORD}
    
    # Get count of unread emails
    ${count}=    Get Email Count    status=UNSEEN
    Log    Found ${count} unread emails
    
    Close Mailbox

Extract Subject and From - Multipart Email
    [Documentation]    Proper way to extract headers from multipart emails
    ...                Uses Walk Multipart Email + Get Multipart Field
    [Tags]    verified    multipart    headers
    
    Open Mailbox    host=${GMAIL_HOST}    user=${GMAIL_USER}    password=${GMAIL_PASSWORD}
    
    # Wait for email
    ${email_index}=    Wait For Email    timeout=${TIMEOUT}
    
    # Walk multipart structure to access headers
    ${parts}=    Walk Multipart Email    ${email_index}
    
    # Now we can access header fields
    ${subject}=    Get Multipart Field    Subject
    ${from}=    Get Multipart Field    From
    ${to}=    Get Multipart Field    To
        ${date}=    Get Multipart Field    Date
    
    Log    Subject: ${subject}
    Log    From: ${from}
    Log    To: ${to}
    Log    Date: ${date}
    
    # Walk through parts to find HTML content
    FOR    ${i}    IN RANGE    ${parts}
        Walk Multipart Email    ${email_index}
        ${content_type}=    Get Multipart Content Type
        
        # Process only HTML parts
        Run Keyword If    '${content_type}' == 'text/html'
        ...    Process HTML Part
        
        # Process plain text parts
        Run Keyword If    '${content_type}' == 'text/plain'
        ...    Process Plain Text Part
    END
    
    Close Mailbox

Extract and Open Link From Email
    [Documentation]    VERIFIED: Extracts link from email and opens it
    [Tags]    verified    link    automation
    
    Open Mailbox    host=${GMAIL_HOST}    user=${GMAIL_USER}    password=${GMAIL_PASSWORD}
    
    # Wait for email with link
    ${email_index}=    Wait For Email    subject=Activation Link    timeout=${TIMEOUT}
    
    # Get all links from email body
    @{links}=    Get Links From Email    ${email_index}
    Log    Found links: ${links}
    
    # Get first link as string
    ${first_link}=    Set Variable    ${links}[0]
    Log    First link: ${first_link}
    
    # OR: Open link directly (returns HTML content of opened URL)
    ${html}=    Open Link From Email    ${email_index}    link_index=0
    Should Contain    ${html}    Welcome
    
    Close Mailbox

*** Keywords ***
Process HTML Part
    [Documentation]    Processes HTML content from multipart email
    ${payload}=    Get Multipart Payload    decode=True
    Log    HTML Content: ${payload}
    Should Contain    ${payload}    expected text

Process Plain Text Part
    [Documentation]    Processes plain text content from multipart email
    ${payload}=    Get Multipart Payload    decode=True
    Log    Plain Text Content: ${payload}