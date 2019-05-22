INSTRUCTIONS FOR SETTING UP:
----------------------------

Unzip 'BlockChat.zip'

1. Open up Xcode
2. 'Create new project' -> 'Single-View app'
3. Generate random project..
4. Change deployment target to 11.2 (Other versions should work as well, but for best results 11.2 should be used)
5. Delete all project files, except "Info.plist" in Xcode (eg. AppDelegate.swift, etc.. except the folder itself and the other 'Products' folder - click on "Move to Trash")
6. Drag all the documents from the 'BlockChat' folder provided into the (empty) project folder -> click 'finish' -> click 'create bridging header'.. Then close Xcode
7. Go to the main folder with the command line (should have the project folder and '(abcde).xcodeproj' file), and type 'pod init'

			( ** If cocoa pods are not installed, type 'sudo gem install cocoapods', or follow guide at https://guides.cocoapods.org/using/getting-started.html ** )

8. Open the new 'PodFile' with a text editor
9. Under "# Pods for (abcde) add the following:

pod 'Firebase/Core'
pod 'Firebase/Auth'
pod 'Firebase/Storage'
pod 'Firebase/Database'
pod 'Alamofire', '~> 4.0'

10. Save and close file
11. Type 'pod install' into cmd
12. Open up the project folder with all the code and open the '(abcde)-Bridging-Header.h' file with a text editor
13. Add the following line, save and close the file:

#import "RNCryptor.h"

14. Go back to the main folder, and double click the '(abcde).xcworkspace' file ( **IMPORTANT** open the .xcworkspace file when using the code at all times )

	**********************************************
	*---- App should build and run as normal ----*
	**********************************************

If build errors occur, the following steps may help:

1. Click on 'blockchain.xcdatamodeld' file, click on 'Blockchain' under 'Entities', and choose the "Data model inspector" mode on the right.
	Change 'Module' to -> "Current Product Module"
	Change 'Codegen' to -> "Manual/None"

2. Click on "DataModel.xcdatamodeld" file, click on 'Blockchain' under 'Entities', and choose the "Data model inspector" mode on the right.
	Change 'Module' to -> "Current Product Module"
	Change 'Codegen' to -> "Manual/None"

3. Click on 'GoogleService-Info.plist' file, and rename "BUNDLE_ID" to whatever the bundle identifier of the project is

To find this, click on the root project file,
(Top left button) Choose the project under "Targets" option
Under "General", "Identity" should be "Bundle Identifier".. rename the "BUNDLE_ID" value with this

4. Click on the root project file, "Target", "General", Change "Main interface" value to "Login.storyboard" file
   Change "Launch Screen File" to "LaunchScreen.storyboard" file.



---------------------------------
If any issues persist, please email me at:	e.kruminis@lancaster.ac.uk