# source https://download.qt.io/archive/qt/5.9/5.9.2/qt-opensource-windows-x86-5.9.2.exe.mirrorlist

$packageName = 'qt-opensource-windows-x86'

# ** FINAL OPENSOURCE OFFLINE INSTALLER **
$qt_major = '5'
$qt_minor = '12'
$qt_patch = '10'

$qt_ver = "$qt_major.$qt_minor.$qt_patch"
$qt_major_minor = "$qt_major.$qt_minor"

$installer = "$packageName-$qt_ver.exe"

$url = "http://download.qt.io/official_releases/qt/$qt_major_minor/$qt_ver/$installer"

$installDir = "\\Qt"

# component names https://github.com/qtproject/qtsdk/tree/master/packaging-tools/configurations/pkg_templates/pkg_qt5_5101
$selectedPackages = 'qt.qt5.5101.win64_msvc2017_64'

$installer_script = @"

function abortInstaller()
{
    installer.setDefaultPageVisible(QInstaller.Introduction, false);
    installer.setDefaultPageVisible(QInstaller.TargetDirectory, false);
    installer.setDefaultPageVisible(QInstaller.ComponentSelection, false);
    installer.setDefaultPageVisible(QInstaller.ReadyForInstallation, false);
    installer.setDefaultPageVisible(QInstaller.StartMenuSelection, false);
    installer.setDefaultPageVisible(QInstaller.PerformInstallation, false);
    installer.setDefaultPageVisible(QInstaller.LicenseCheck, false);

    var abortText = "<font color='red' size=3>" + qsTr("Installation failed:") + "</font>";

    var error_list = installer.value("component_errors").split(";;;");
    abortText += "<ul>";
    // ignore the first empty one
    for (var i = 0; i < error_list.length; ++i) {
        if (error_list[i] !== "") {
            log(error_list[i]);
            abortText += "<li>" + error_list[i] + "</li>"
        }
    }
    abortText += "</ul>";
    installer.setValue("FinishedText", abortText);
}

function log() {
    var msg = ["QTCI: "].concat([].slice.call(arguments));
    console.log(msg.join(" "));
}

function Controller() {
	//set in silent mode no gui
	gui.setSilent(true);
    installer.installationFinished.connect(function() {
        gui.clickButton(buttons.NextButton);
    });
    installer.setMessageBoxAutomaticAnswer("OverwriteTargetDirectory", QMessageBox.Yes);
    installer.setMessageBoxAutomaticAnswer("installationErrorWithRetry", QMessageBox.Ignore);
}

Controller.prototype.WelcomePageCallback = function() {
    log("Welcome Page");
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.CredentialsPageCallback = function() {
    gui.clickButton(buttons.CommitButton);
}

Controller.prototype.StartMenuDirectoryPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ComponentSelectionPageCallback = function() {

    var components = installer.components();
    log("Available components: " + components.length);

    for (var i = 0 ; i < components.length ;i++) {
        log(components[i].name);
    }

    log("Select components");

    function trim(str) {
        return str.replace(/^ +/,"").replace(/ *$/,"");
    }

    var widget = gui.currentPageWidget();

    var packages = trim("$selectedPackages").split(",");
    if (packages.length > 0 && packages[0] !== "") {
        widget.deselectAll();
        for (var i in packages) {
            var pkg = trim(packages[i]);
	        log("Select " + pkg);
	        widget.selectComponent(pkg);
        }
    } else {
       log("Use default component list");
    }

    gui.clickButton(buttons.NextButton);
}

Controller.prototype.IntroductionPageCallback = function() {
    log("Introduction Page");
    log("Retrieving meta information from remote repository");
    gui.clickButton(buttons.NextButton);
}


Controller.prototype.TargetDirectoryPageCallback = function() {
    log("Set target installation page: $installDir");
    var widget = gui.currentPageWidget();

    if (widget != null) {
        widget.TargetDirectoryLineEdit.setText("$installDir");
    }
    
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.LicenseAgreementPageCallback = function() {
    log("Accept license agreement");
    var widget = gui.currentPageWidget();

    if (widget != null) {
        widget.AcceptLicenseRadioButton.setChecked(true);
    }

    gui.clickButton(buttons.NextButton);

}

Controller.prototype.ReadyForInstallationPageCallback = function() {
    log("Ready to install");
    gui.clickButton(buttons.CommitButton);
}

Controller.prototype.PerformInstallationPageCallback = function() {
    log("PerformInstallationPageCallback");
    gui.clickButton(buttons.CommitButton);
}

Controller.prototype.FinishedPageCallback = function() {
    var widget = gui.currentPageWidget();

    if (widget.LaunchQtCreatorCheckBoxForm) {
        // No this form for minimal platform
        widget.LaunchQtCreatorCheckBoxForm.launchQtCreatorCheckBox.setChecked(false);
    }
    gui.clickButton(buttons.FinishButton);
}
"@

$out_installer_script = $ExecutionContext.InvokeCommand.ExpandString($installer_script)

$tmp_install_script = New-TemporaryFile

$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines($tmp_install_script.FullName, $out_installer_script, $Utf8NoBomEncoding)

#args: "--platform minimal" are not available in windows
$installerArgs = "-v "

echo ".\$installer" $installerArgs --script $tmp_install_script.FullName

& ".\$installer" $installerArgs --script $tmp_install_script.FullName

# cleanup
# del $tmp_install_script.FullName
