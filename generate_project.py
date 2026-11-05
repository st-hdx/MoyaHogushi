#!/usr/bin/env python3
"""Generate MoyaHogushi.xcodeproj (pbxproj + shared scheme) and the asset catalog skeleton.

Source files are discovered from disk, so adding a .swift file only requires re-running this script.
IDs are derived from names, so regenerating produces no diff unless the file list changes.
"""

import hashlib
import os

APP = "MoyaHogushi"
BUNDLE_ID = "com.pandagiken.moyahogushi.app"
TEAM = "Y5RBKYD4FY"
DEPLOYMENT_TARGET = "16.0"

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(ROOT, APP)


def uid(name: str) -> str:
    return hashlib.md5(f"{APP}:{name}".encode()).hexdigest()[:24].upper()


def swift_files(subdir: str = ""):
    base = os.path.join(SRC, subdir)
    return sorted(f for f in os.listdir(base) if f.endswith(".swift") and os.path.isfile(os.path.join(base, f)))


root_files = swift_files()
model_files = swift_files("Models")
view_files = swift_files("Views")

sources = (
    [(f, f) for f in root_files]
    + [(f, f"Models/{f}") for f in model_files]
    + [(f, f"Views/{f}") for f in view_files]
)

PKG_REF = uid("pkg:purchases-ios-spm")
PKG_PRODUCT = uid("pkgprod:RevenueCat")
BF_PKG = uid("bf:RevenueCat")

build_files = "\n".join(
    f"\t\t{uid('bf:' + p)} /* {n} in Sources */ = {{isa = PBXBuildFile; fileRef = {uid('fr:' + p)} /* {n} */; }};"
    for n, p in sources
)
build_files += (
    f"\n\t\t{uid('bf:Assets')} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {uid('fr:Assets')} /* Assets.xcassets */; }};"
    f"\n\t\t{uid('bf:Preview')} /* Preview Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {uid('fr:Preview')} /* Preview Assets.xcassets */; }};"
    f"\n\t\t{BF_PKG} /* RevenueCat in Frameworks */ = {{isa = PBXBuildFile; productRef = {PKG_PRODUCT} /* RevenueCat */; }};"
)

file_refs = f"\t\t{uid('product')} /* {APP}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {APP}.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n"
file_refs += "\n".join(
    f'\t\t{uid("fr:" + p)} /* {n} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {n}; sourceTree = "<group>"; }};'
    for n, p in sources
)
file_refs += (
    f'\n\t\t{uid("fr:Assets")} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};'
    f'\n\t\t{uid("fr:Entitlements")} /* {APP}.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = {APP}.entitlements; sourceTree = "<group>"; }};'
    f'\n\t\t{uid("fr:Preview")} /* Preview Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "Preview Assets.xcassets"; sourceTree = "<group>"; }};'
)


def children(files, prefix=""):
    return "\n".join(f"\t\t\t\t{uid('fr:' + prefix + n)} /* {n} */," for n in files)


source_phase_files = "\n".join(
    f"\t\t\t\t{uid('bf:' + p)} /* {n} in Sources */," for n, p in sources
)

PROJECT_SETTINGS = """\
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = {target};
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
""".replace("{target}", DEPLOYMENT_TARGET)

TARGET_SETTINGS = f"""\
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = {APP}/{APP}.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\\"{APP}/Preview Content\\"";
				DEVELOPMENT_TEAM = {TEAM};
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "もやほぐし";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.lifestyle";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
"""

pbxproj = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{build_files}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{file_refs}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{uid('phase:frameworks')} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{BF_PKG} /* RevenueCat in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{uid('group:main')} = {{
			isa = PBXGroup;
			children = (
				{uid('group:app')} /* {APP} */,
				{uid('group:products')} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{uid('group:products')} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{uid('product')} /* {APP}.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{uid('group:app')} /* {APP} */ = {{
			isa = PBXGroup;
			children = (
{children(root_files)}
				{uid('group:models')} /* Models */,
				{uid('group:views')} /* Views */,
				{uid('fr:Assets')} /* Assets.xcassets */,
				{uid('fr:Entitlements')} /* {APP}.entitlements */,
				{uid('group:preview')} /* Preview Content */,
			);
			path = {APP};
			sourceTree = "<group>";
		}};
		{uid('group:models')} /* Models */ = {{
			isa = PBXGroup;
			children = (
{children(model_files, "Models/")}
			);
			path = Models;
			sourceTree = "<group>";
		}};
		{uid('group:views')} /* Views */ = {{
			isa = PBXGroup;
			children = (
{children(view_files, "Views/")}
			);
			path = Views;
			sourceTree = "<group>";
		}};
		{uid('group:preview')} /* Preview Content */ = {{
			isa = PBXGroup;
			children = (
				{uid('fr:Preview')} /* Preview Assets.xcassets */,
			);
			path = "Preview Content";
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{uid('target')} /* {APP} */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {uid('cfglist:target')} /* Build configuration list for PBXNativeTarget "{APP}" */;
			buildPhases = (
				{uid('phase:sources')} /* Sources */,
				{uid('phase:frameworks')} /* Frameworks */,
				{uid('phase:resources')} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = {APP};
			packageProductDependencies = (
				{PKG_PRODUCT} /* RevenueCat */,
			);
			productName = {APP};
			productReference = {uid('product')} /* {APP}.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{uid('project')} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1420;
				LastUpgradeCheck = 1420;
				TargetAttributes = {{
					{uid('target')} = {{
						CreatedOnToolsVersion = 14.2;
					}};
				}};
			}};
			buildConfigurationList = {uid('cfglist:project')} /* Build configuration list for PBXProject "{APP}" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = ja;
			hasScannedForEncodings = 0;
			knownRegions = (
				ja,
				Base,
			);
			mainGroup = {uid('group:main')};
			packageReferences = (
				{PKG_REF} /* XCRemoteSwiftPackageReference "purchases-ios-spm" */,
			);
			productRefGroup = {uid('group:products')} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{uid('target')} /* {APP} */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{uid('phase:resources')} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{uid('bf:Preview')} /* Preview Assets.xcassets in Resources */,
				{uid('bf:Assets')} /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{uid('phase:sources')} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{source_phase_files}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{uid('cfg:project:debug')} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{PROJECT_SETTINGS}				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{uid('cfg:project:release')} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{PROJECT_SETTINGS}				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				MTL_ENABLE_DEBUG_INFO = NO;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{uid('cfg:target:debug')} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{TARGET_SETTINGS}			}};
			name = Debug;
		}};
		{uid('cfg:target:release')} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{TARGET_SETTINGS}			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{uid('cfglist:project')} /* Build configuration list for PBXProject "{APP}" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{uid('cfg:project:debug')} /* Debug */,
				{uid('cfg:project:release')} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{uid('cfglist:target')} /* Build configuration list for PBXNativeTarget "{APP}" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{uid('cfg:target:debug')} /* Debug */,
				{uid('cfg:target:release')} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */

/* Begin XCRemoteSwiftPackageReference section */
		{PKG_REF} /* XCRemoteSwiftPackageReference "purchases-ios-spm" */ = {{
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/RevenueCat/purchases-ios-spm.git";
			requirement = {{
				kind = upToNextMajorVersion;
				minimumVersion = 5.0.0;
			}};
		}};
/* End XCRemoteSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		{PKG_PRODUCT} /* RevenueCat */ = {{
			isa = XCSwiftPackageProductDependency;
			package = {PKG_REF} /* XCRemoteSwiftPackageReference "purchases-ios-spm" */;
			productName = RevenueCat;
		}};
/* End XCSwiftPackageProductDependency section */
	}};
	rootObject = {uid('project')} /* Project object */;
}}
"""

scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{uid('target')}"
               BuildableName = "{APP}.app"
               BlueprintName = "{APP}"
               ReferencedContainer = "container:{APP}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{uid('target')}"
            BuildableName = "{APP}.app"
            BlueprintName = "{APP}"
            ReferencedContainer = "container:{APP}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{uid('target')}"
            BuildableName = "{APP}.app"
            BlueprintName = "{APP}"
            ReferencedContainer = "container:{APP}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""


def write(path: str, content: str):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as f:
        f.write(content)


XCASSET_INFO = '{\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}\n'

write(f"{APP}.xcodeproj/project.pbxproj", pbxproj)
write(f"{APP}.xcodeproj/xcshareddata/xcschemes/{APP}.xcscheme", scheme)
write(f"{APP}/Assets.xcassets/Contents.json", XCASSET_INFO)
write(f"{APP}/Preview Content/Preview Assets.xcassets/Contents.json", XCASSET_INFO)
write(
    f"{APP}/Assets.xcassets/AccentColor.colorset/Contents.json",
    '{\n  "colors" : [\n    {\n      "color" : {\n        "color-space" : "srgb",\n        "components" : {\n'
    '          "alpha" : "1.000",\n          "blue" : "0x3C",\n          "green" : "0x74",\n          "red" : "0xD9"\n'
    '        }\n      },\n      "idiom" : "universal"\n    }\n  ],\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}\n',
)
write(
    f"{APP}/Assets.xcassets/AppIcon.appiconset/Contents.json",
    '{\n  "images" : [\n    {\n      "filename" : "AppIcon-1024.png",\n      "idiom" : "universal",\n'
    '      "platform" : "ios",\n      "size" : "1024x1024"\n    }\n  ],\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}\n',
)

print(f"Done: {APP}.xcodeproj ({len(sources)} source files)")
