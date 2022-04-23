*** Settings ***

*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault
Library           OperatingSystem

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    Open the intranet website
    Download the order excel file
    Fill the form using the data from the csv file
    Create ZIP package from PDF files
    [Teardown]    Close Browser

*** Keywords ***
Download the order excel file
    Add text Input    filepath    label=Enter csv file path
    ${result}=    Run Dialog
    Download    ${result.filepath}    overwrite=True

Open the intranet website
    ${secret}=    Get Secret    RobocorpIntranet
    Open Available Browser    ${secret}[RobocorpIntranetUrl]    maximized=true

Close the annoying modal
    Wait Until Element Is Visible    //button[text()='OK']
    Click Button    OK

Fill the form using the data from the csv file
    ${tables}=
    ...    Read Table From Csv
    ...    ${CURDIR}${/}orders.csv
    ...    header=True
    FOR    ${row}    IN    @{tables}
        Close the annoying modal
        Select From List By Value    head    ${row}[Head]
        Select Radio Button    body    ${row}[Body]
        Input Text    //input[@type='number']    ${row}[Legs]
        Input Text    address    ${row}[Address]
        Click Button    //*[@id='preview']
        ${pdf}=    Wait Until Keyword Succeeds    10x    0.5s    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Click Button    //*[@id='order-another']
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${row}[Order number]
    END

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${row}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${OUTPUT_DIR}${/}${row}.pdf
    Remove File    ${OUTPUT_DIR}${/}${row}.png

Store the receipt as a PDF file
    [Arguments]    ${row}
    Click Button    //*[@id='order']
    ${receipt_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_results_html}    ${OUTPUT_DIR}${/}${row}.pdf
    [Return]    ${OUTPUT_DIR}${/}${row}.pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    //div[@id='robot-preview-image']
    Screenshot    //div[@id='robot-preview-image']    ${OUTPUT_DIR}${/}${row}.png
    [Return]    ${OUTPUT_DIR}${/}${row}.png

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}/PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}    ${zip_file_name}    include=*.pdf
    Remove Files    ${OUTPUT_DIR}/*.pdf
