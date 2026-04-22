*** Settings ***
Library                         QForce
Resource                        ../resources/common.robot
Suite Setup                     Setup Browser
Suite Teardown                  End suite

*** Variables ***
${EXPERIENCE_NAME}              ${Agentforce.EXPERIENCE_NAME}
${EXPERIENCE_DESCRIPTION}       ${Agentforce.EXPERIENCE_DESCRIPTION}
${EXPERIENCE_TYPE}              ${Agentforce.EXPERIENCE_TYPE}
*** Test Cases ***

AgentforceSimple
    #Data Setup
    ${date}=                    Get Current Date            result_format=%Y-%m-%d
    ${sessionId}=               Manage Session Records      ${EXPERIENCE_NAME}          ${date}
    GoTo                        ${ExperienceUrl}

    # Agent Interactions - Initial Inquiry
    ${firstAgentReply}          Send Prompt                 What can you tell me about the ${EXPERIENCE_NAME}?
    VerifyTextSimilarity        ${firstAgentReply}          Could you please provide your email address and membership number so I can look up your details and provide you with the most accurate information?    threshold=0.25

    # Agent Interactions - Provide Credentials
    ${secondAgentReply}         Send Prompt                 My email address is sofiarodriguez@example.com and my membership number is 10008155
    VerifyResponseSimilarity    ${secondAgentReply}         ${EXPERIENCE_NAME} ${EXPERIENCE_DESCRIPTION} ${EXPERIENCE_TYPE}     threshold=0.5

    # Agent Interactions - Attempt to overbook
    ${thirdAgentReply}          Send Prompt                 I would like to book this experience for ${date} for 30 guests
    VerifyResponseRelevance     I would like to book this experience for ${date} for 30 guests                ${thirdAgentReply}    threshold=0.25

    # Agent Interactions - Successful booking
    ${fourthAgentReply}         Send Prompt                 Lets book for 2 guests instead
    VerifyResponseHelpfulness                               Lets book for 2 guests instead                    ${fourthAgentReply}    threshold=0.25

    #Salesforce Validations
    JwtLogin
    NavigateToBooking           ${date}                     ${EXPERIENCE_NAME}
    VerifyField                 Number of Guests            2
    VerifyField                 Contact                     Sofia Rodriguez             tag=a
    VerifyField                 Experience Name             ${EXPERIENCE_NAME}                                partial_match=True
    VerifyField                 Status                      Confirmed

    NavigateToSession           ${date}                     ${EXPERIENCE_NAME}
    VerifyField                 Experience                  ${EXPERIENCE_NAME}                                tag=a                 partial_match=True
    VerifyField                 Booked Slots                2
