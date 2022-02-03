// Copyright 2021 Switt Kongdachalert

#import "FaceMeshIOSLib.h"

#import "mediapipe/objc/MPPCameraInputSource.h"
#import "mediapipe/objc/MPPGraph.h"

#include <map>
#include <string>
#include <utility>

#include "mediapipe/framework/formats/matrix_data.pb.h"
#include "mediapipe/framework/calculator_framework.h"
#include "mediapipe/modules/face_geometry/protos/face_geometry.pb.h"

static NSString* const kGraphName = @"face_effect_gpu";

static const char* kInputStream = "input_video";
static const char* kOutputStream = "output_video";
static const char* kMultiFaceGeometryStream = "multi_face_geometry";
static const char* kVideoQueueLabel = "com.google.mediapipe.example.videoQueue";
static const char* kUseFaceDetectionInputSourceInputSidePacket = "use_face_detection_input_source";

static const BOOL kUseFaceDetectionInputSource = NO;

@interface FaceMeshIOSLib () <MPPGraphDelegate>
@property(nonatomic) MPPGraph* graph;
@end

@implementation FaceMeshIOSLib {
}

#pragma mark - Cleanup methods

- (void)dealloc {
  self.graph.delegate = nil;
  [self.graph cancel];
  // Ignore errors since we're cleaning up.
  [self.graph closeAllInputStreamsWithError:nil];
  [self.graph waitUntilDoneWithError:nil];
}

#pragma mark - MediaPipe graph methods

+ (MPPGraph*)loadGraphFromResource:(NSString*)resource {
  // Load the graph config resource.
  NSError* configLoadError = nil;
  NSBundle* bundle = [NSBundle bundleForClass:[self class]];
  if (!resource || resource.length == 0) {
    return nil;
  }
  NSURL* graphURL = [bundle URLForResource:resource withExtension:@"binarypb"];
  NSData* data = [NSData dataWithContentsOfURL:graphURL options:0 error:&configLoadError];
  if (!data) {
    NSLog(@"Failed to load MediaPipe graph config: %@", configLoadError);
    return nil;
  }

  // Parse the graph config resource into mediapipe::CalculatorGraphConfig proto object.
  mediapipe::CalculatorGraphConfig config;
  config.ParseFromArray(data.bytes, data.length);

  // Pass the kUseFaceDetectionInputSource flag value as an input side packet into the graph.
  std::map<std::string, mediapipe::Packet> side_packets;
  side_packets[kUseFaceDetectionInputSourceInputSidePacket] =
      mediapipe::MakePacket<bool>(kUseFaceDetectionInputSource);

  // Create MediaPipe graph with mediapipe::CalculatorGraphConfig proto object.
  MPPGraph* newGraph = [[MPPGraph alloc] initWithGraphConfig:config];
  [newGraph addSidePackets:side_packets];
  [newGraph addFrameOutputStream:kOutputStream outputPacketType:MPPPacketTypePixelBuffer];
  [newGraph addFrameOutputStream:kMultiFaceGeometryStream outputPacketType:MPPPacketTypeRaw];
  return newGraph;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.graph = [[self class] loadGraphFromResource:kGraphName];
    self.graph.delegate = self;
    
    // // Set maxFramesInFlight to a small value to avoid memory contention
    // // for real-time processing.
    self.graph.maxFramesInFlight = 1;
    NSLog(@"inited graph %@", kGraphName);
  }
  return self;
}

- (void)startGraph {
  NSError* error;
  if (![self.graph startWithError:&error]) {
    NSLog(@"Failed to start graph: %@", error);
  }
  NSLog(@"Started graph %@", kGraphName);
}

#pragma mark - MPPGraphDelegate methods

// Receives CVPixelBufferRef from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
    didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
              fromStream:(const std::string&)streamName {
  NSLog(@"recv pixelBuffer from %@", @(streamName.c_str()));
}

// Receives a raw packet from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
     didOutputPacket:(const ::mediapipe::Packet&)packet
          fromStream:(const std::string&)streamName {
	if (streamName == kMultiFaceGeometryStream) {
		if (packet.IsEmpty()) {
		      	NSLog(@"[TS:%lld] No face geometry", packet.Timestamp().Value());
			return;
		}

		const auto& multiFaceGeometry = 
			packet.Get<std::vector<::mediapipe::face_geometry::FaceGeometry>>();
		NSMutableArray<FaceGeometryWrapper *>*output = [NSMutableArray new];
		for (int face_index = 0; face_index < multiFaceGeometry.size(); ++face_index) {
			const auto& geometry = multiFaceGeometry[face_index];
			FaceGeometryWrapper *wrapper = [FaceGeometryWrapper new];
			MatrixWrapper *matrix = [MatrixWrapper new];
			MeshWrapper *mesh = [MeshWrapper new];

			matrix.rows = geometry.pose_transform_matrix().rows();
			matrix.cols = geometry.pose_transform_matrix().cols();

			NSMutableArray<NSNumber *> *packedData = [NSMutableArray new];
			for (int i = 0; i < geometry.pose_transform_matrix().packed_data().size(); i++) {
				[packedData addObject:[NSNumber numberWithFloat:geometry.pose_transform_matrix().packed_data()[i]]];
			}
			matrix.data = packedData;

			NSMutableArray<NSNumber *> *vertexBuffer = [NSMutableArray new];
			for (int i = 0; i < geometry.mesh().vertex_buffer().size(); i++) {
				[vertexBuffer addObject:[NSNumber numberWithUnsignedInteger:geometry.mesh().vertex_buffer()[i]]];
			}
			mesh.vertexBuffer = vertexBuffer;

			NSMutableArray<NSNumber *> *indexBuffer = [NSMutableArray new];
			for (int i = 0; i < geometry.mesh().index_buffer().size(); i++) {
				[vertexBuffer addObject:[NSNumber numberWithUnsignedInteger:geometry.mesh().index_buffer()[i]]];
			}
			mesh.indexBuffer = indexBuffer;

			wrapper.meshWrapper = mesh;
			wrapper.poseTransformMatrix = matrix;
			[output addObject: wrapper];
		}
		[self.delegate didRecieveMultiFaceGeometry:output];
	}
}

- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer {
  const auto ts =
      mediapipe::Timestamp(self.timestamp++ * mediapipe::Timestamp::kTimestampUnitsPerSecond);
  NSError* err = nil;
  NSLog(@"%zu", self.timestamp);

  auto sent = [self.graph sendPixelBuffer:imageBuffer
                                        intoStream:kInputStream
                                        packetType:MPPPacketTypePixelBuffer
                                         timestamp:ts
                                    allowOverwrite:NO
                                             error:&err];

  if (err) {
    NSLog(@"sendPixelBuffer error: %@", err);
  }
}

@end


@implementation FaceMeshIOSLibFaceLandmarkPoint
@end

@implementation FaceMeshIOSLibNormalizedRect
@end

@implementation FaceGeometryWrapper
@end

@implementation MeshWrapper
@end

@implementation MatrixWrapper
@end
