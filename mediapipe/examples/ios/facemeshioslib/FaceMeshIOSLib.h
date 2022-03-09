// Copyright 2021 Switt Kongdachalert

#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>

@interface MeshWrapper : NSObject
@property (nonatomic) NSArray *vertexBuffer;
@property (nonatomic) NSArray *indexBuffer; 
@end

@interface MatrixWrapper : NSObject
@property (nonatomic) int32_t rows;
@property (nonatomic) int32_t cols;
@property (nonatomic) NSArray *data;
@end

@interface FaceGeometryWrapper : NSObject
@property (nonatomic) MeshWrapper *meshWrapper;
@property (nonatomic) MatrixWrapper *poseTransformMatrix;
@end

@interface FaceMeshIOSLibFaceLandmarkPoint : NSObject
@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float z;
@end

@interface FaceMeshIOSLibNormalizedRect : NSObject
@property (nonatomic) float centerX;
@property (nonatomic) float centerY;
@property (nonatomic) float height;
@property (nonatomic) float width;
@property (nonatomic) float rotation;
@end

typedef NS_ENUM(NSUInteger, GraphType) {
  kFaceGeometry,
  kSelfieSegmentation
};

@protocol FaceMeshIOSLibDelegate <NSObject>
@optional
- (void)didRecieveMultiFaceGeometry:(NSArray <FaceGeometryWrapper *>*)multiFaceGeometry;
/** 
 * Array of faces, with faces represented by arrays of face landmarks 
*/
- (void)didReceiveFaces:(NSArray <NSArray<FaceMeshIOSLibFaceLandmarkPoint *>*>*)faces;
/** 
 * Array of faces, with faces represented by arrays of face landmarks 
*/
- (void)didReceiveFaceBoxes:(NSArray <FaceMeshIOSLibNormalizedRect *>*)faces;

- (void)didReceiveSelfiSegmentationMask:(CVPixelBufferRef)pixelBuffer;
@end

@interface FaceMeshIOSLib : NSObject
- (instancetype)init:(GraphType)graphType;
- (void)startGraph;
- (void)processVideoFrame:(CVPixelBufferRef)imageBuffe;
@property(weak, nonatomic) id<FaceMeshIOSLibDelegate> delegate;
@property(nonatomic) size_t timestamp;
@end
