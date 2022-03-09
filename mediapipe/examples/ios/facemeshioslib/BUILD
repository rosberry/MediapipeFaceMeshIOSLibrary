load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application", "ios_framework")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load(
    "//mediapipe/examples/ios:bundle_id.bzl",
    "BUNDLE_ID_PREFIX",
    "example_provisioning",
)

licenses(["notice"])  # Apache 2.0

MIN_IOS_VERSION = "11.1"

IOS_FAMILIES = [
    "iphone",
    "ipad",
]
FRAMEWORK_HEADERS = [
    "FaceMeshIOSLib.h",
]

ios_framework(
    name = "FaceMeshIOSLibFramework",
    hdrs = FRAMEWORK_HEADERS,
    bundle_id = BUNDLE_ID_PREFIX + ". FaceMeshIOSLibFramework",
    bundle_name = "FaceMeshIOSLibFramework",
    families = IOS_FAMILIES,
    infoplists = [
        "//mediapipe/examples/ios/common:Info.plist",
    ],
    minimum_os_version = MIN_IOS_VERSION,
    visibility = ["//visibility:public"],
    deps = [
        ":FaceMeshIOSLib",
        "@ios_opencv//:OpencvFramework",
	      "//mediapipe/framework/formats:matrix_data_cc_proto",
        "//mediapipe/graphs/face_effect:face_effect_gpu_deps",
        "//mediapipe/modules/face_geometry/protos:face_geometry_cc_proto",
    ],
)

# amalgamate stuff in from the facemeshgpu iOS example
objc_library(
    name = "FaceMeshIOSLib",
    srcs = [
        "FaceMeshIOSLib.mm",
    ],
    hdrs = FRAMEWORK_HEADERS,
    copts = ["-std=c++17"],  # https://github.com/google/mediapipe/issues/2275#issuecomment-877145926
    data = [
    "//mediapipe/graphs/face_mesh:pure_face_mesh_mobile_gpu.binarypb",
    "//mediapipe/modules/face_detection:face_detection_short_range.tflite",
    "//mediapipe/graphs/face_effect:face_effect_gpu.binarypb",
    "//mediapipe/graphs/face_effect/data:facepaint.pngblob",
    "//mediapipe/graphs/face_effect/data:glasses.binarypb",
    "//mediapipe/graphs/face_effect/data:glasses.pngblob",
    "//mediapipe/modules/face_geometry/data:geometry_pipeline_metadata.binarypb",
    "//mediapipe/modules/face_geometry/data:geometry_pipeline_metadata_detection.binarypb",
    "//mediapipe/modules/face_geometry/data:geometry_pipeline_metadata_landmarks.binarypb",
    "//mediapipe/modules/face_landmark:face_landmark.tflite",
    "//mediapipe/graphs/selfie_segmentation:selfie_segmentation_gpu.binarypb",
    "//mediapipe/modules/selfie_segmentation:selfie_segmentation.tflite",
    ],
    deps = [
        "//mediapipe/objc:mediapipe_framework_ios",
        "//mediapipe/objc:mediapipe_input_sources_ios",
        "//mediapipe/calculators/core:packet_presence_calculator",
        "//mediapipe/examples/ios/common:CommonMediaPipeAppLibrary",
    ] + select({
        # "//mediapipe:ios_i386": [],
        # "//mediapipe:ios_x86_64": [],
        "//conditions:default": [
            "//mediapipe/graphs/face_mesh:mobile_calculators",
            "//mediapipe/framework/formats:landmark_cc_proto",
            "//mediapipe/framework/formats:matrix_data_cc_proto",
            "//mediapipe/graphs/face_effect:face_effect_gpu_deps",
            "//mediapipe/modules/face_geometry/protos:face_geometry_cc_proto",
            "//mediapipe/graphs/selfie_segmentation:selfie_segmentation_gpu_deps",
        ],
    }),
)
