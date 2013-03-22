//
//  ANViewController.h
//  ImageMesh
//
//  Created by Alex Nichol on 3/22/13.
//  Copyright (c) 2013 Alex Nichol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#define kImageHorizontalVertices 20
#define kImageVerticalVertices 20

@interface ANViewController : GLKViewController {
    GLfloat * vertexData;
    GLuint vertexCount;
    GLfloat * textureCoords;
    GLKTextureInfo * imageTexture;
    
    GLKVector2 * vertexBasePositions;
    GLKVector2 * vertexPositions;
    GLKVector2 * vertexVelocities;
    
    NSDate * lastAnimation;
    
    BOOL isDragging;
    GLKVector2 touchLastPoint;
    int touchingVertex;
    
    GLfloat windowHeight;
    GLfloat windowWidth;
}

@property (strong, nonatomic) EAGLContext * context;
@property (strong, nonatomic) GLKBaseEffect * effect;

- (void)setupGL;
- (void)tearDownGL;
- (void)generateVertexData;
- (void)applyCentralForces:(NSTimeInterval)delay;

- (GLKVector2)coordinateForPoint:(CGPoint)p;

@end
