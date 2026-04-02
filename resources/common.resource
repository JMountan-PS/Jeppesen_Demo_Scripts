*** Settings ***
Library                         QWeb
Library                         QForce
Library                         QVision
Library                         String
Library                         Collections
Library                         DateTime


*** Keywords ***
Setup Browser
    Set Library Search Order    QForce                        QWeb                        QVision
    Open Browser                about:blank                 ${browser}
    SetConfig                   LineBreak                   ${EMPTY}                    #\ue000
    SetConfig                   DefaultTimeout              30s                         #sometimes salesforce is slow


Close All Browser Sessions
    Set Library Search Order    QForce                        QWeb                        QVision
    Close All Browsers


Login
    [Documentation]             Login to Salesforce instance
    Set Library Search Order    QForce                        QWeb                        QVision
    GoTo                        ${login_url}
    TypeText                    Username                    ${username}                 delay=1
    TypeText                    Password                    ${password}
    ClickText                   Log In
    
    # Uncommment with Exercise 8 MFA

    # MFA is only required for unknown devices or browsers, once verified it is not asked for. 
    # To enforce MFA in your SF trial, Setup -> Identity -> Identity Verification -> Require MFA for all direct UI logins to your Salesforce org
    
    # ${MFA_needed}=              Run Keyword And Return Status                           Should Not Be Equal         ${None}         ${MY_SECRET}
    # Log To Console              ${MFA_needed} # When given ${MFA_needed} is true, see Log to Console keyword result
    
    # IF                          ${MFA_needed}
    #     ${mfa_code}=            GetOTP                      ${username}                 ${MY_SECRET}
    #     TypeSecret              Verification Code           ${mfa_code}
    #     ClickText               Verify
    # END


Login As
    [Documentation]       Login As different persona. User needs to be logged into Salesforce with Admin rights
    ...                   before calling this keyword to change persona.
    ...                   Example:
    ...                   LoginAs    Chatter Expert
    [Arguments]           ${persona}
    Set Library Search Order    QForce                        QWeb                        QVision
    ClickText             Setup
    ClickText             Setup for current app
    SwitchWindow          NEW
    TypeText              Search Setup                ${persona}             delay=2
    ClickText             User                        anchor=${persona}      delay=3    # wait for list to populate, then click
    VerifyText            Freeze                      
    ClickText             Login                       anchor=Freeze          delay=1      

Home
    [Documentation]             Navigate to homepage, login if needed
    Set Library Search Order    QForce                        QWeb                        QVision
    GoTo                        ${home_url}
    ${login_status} =           IsText                      To access this page, you have to log in to Salesforce.                  2
    Run Keyword If              ${login_status}             Login                   