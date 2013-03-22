//
//  ANViewController.m
//  ImageMesh
//
//  Created by Alex Nichol on 3/22/13.
//  Copyright (c) 2013 Alex Nichol. All rights reserved.
//

#import "ANViewController.h"


@implementation ANViewController

@synthesize context;
@synthesize effect;

static GLKVector2 _node_force(GLKVector2 nodePosition, GLKVector2 pullPosition, GLfloat steadyLength, GLfloat coeff);

- (void)viewDidLoad
{
    windowWidth = [UIScreen mainScreen].bounds.size.width;
    windowHeight = [UIScreen mainScreen].bounds.size.height;
    
    
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView * view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
}

- (void)dealloc {
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (void)setupGL {
    [EAGLContext setCurrentContext:self.context];
    
    NSString * texturePath = [[NSBundle mainBundle] pathForResource:@"texture" ofType:@"png"];
    imageTexture = [GLKTextureLoader textureWithContentsOfFile:texturePath
                                                       options:nil
                                                         error:nil];

    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.texture2d0.envMode = GLKTextureEnvModeReplace;
    self.effect.texture2d0.target = GLKTextureTarget2D;
    self.effect.texture2d0.name = imageTexture.name;
    GLfloat aspectRatio = windowHeight / windowWidth;
    self.effect.transform.projectionMatrix = GLKMatrix4MakeOrtho(-1, 1, -aspectRatio, aspectRatio, 1, -1);

    
    // generate the vertex coordinates
    GLfloat width = 2 / (GLfloat)kImageHorizontalVertices;
    GLfloat height = 2 / (GLfloat)kImageVerticalVertices;
    GLfloat xInitial = -1;
    GLfloat yInitial = -1;
    int triangleCount = kImageHorizontalVertices * kImageVerticalVertices * 2;
    vertexData = (GLfloat *)malloc(triangleCount * 6 * sizeof(GLfloat));
    textureCoords = (GLfloat *)malloc(triangleCount * 6 * sizeof(GLfloat));
    vertexCount = triangleCount * 3;
    
    int vertexPositionsSize = sizeof(GLKVector2) * (kImageHorizontalVertices + 1) * (kImageVerticalVertices + 1);
    vertexPositions = (GLKVector2 *)malloc(vertexPositionsSize);
    vertexVelocities = (GLKVector2 *)malloc(vertexPositionsSize);
    vertexBasePositions = (GLKVector2 *)malloc(vertexPositionsSize);
    for (int y = 0; y <= kImageVerticalVertices; y++) {
        for (int x = 0; x <= kImageHorizontalVertices; x++) {
            int vertexIndex = x + (y * (kImageHorizontalVertices + 1));
            vertexPositions[vertexIndex] = GLKVector2Make((GLfloat)x * width + xInitial,
                                                          (GLfloat)y * height + yInitial);
            vertexVelocities[vertexIndex] = GLKVector2Make(0, 0);
        }
    }
    memcpy(vertexBasePositions, vertexPositions, vertexPositionsSize);
    
    // generate texture coords
    for (int y = 0; y < kImageVerticalVertices; y++) {
        for (int x = 0; x < kImageHorizontalVertices; x++) {
            int squareIndex = x + (y * kImageHorizontalVertices);
            int vertexIndex = squareIndex * 12; // 12 GLfloats per square
            GLfloat textureIndices[] = {
                // triangle #1
                1 - (GLfloat)x / (GLfloat)kImageHorizontalVertices,
                1 - (GLfloat)y / (GLfloat)kImageVerticalVertices,
                1 - (GLfloat)(x + 1) / (GLfloat)kImageHorizontalVertices,
                1 - (GLfloat)y / (GLfloat)kImageVerticalVertices,
                1 - (GLfloat)(x + 1) / (GLfloat)kImageHorizontalVertices,
                1 - (GLfloat)(y + 1) / (GLfloat)kImageVerticalVertices,
                // triangle #2
                1 - (GLfloat)(x + 1) / (GLfloat)kImageHorizontalVertices,
                1 - (GLfloat)(y + 1) / (GLfloat)kImageVerticalVertices,
                1 - (GLfloat)x / (GLfloat)kImageHorizontalVertices,
                1 - (GLfloat)(y + 1) / (GLfloat)kImageVerticalVertices,
                1 - (GLfloat)x / (GLfloat)kImageHorizontalVertices,
                1 - (GLfloat)y / (GLfloat)kImageVerticalVertices
            };
            memcpy(&textureCoords[vertexIndex], textureIndices, sizeof(GLfloat) * 12);
        }
    }
    [self generateVertexData];
}

- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];
    self.effect = nil;
}

- (void)generateVertexData {
    for (int y = 0; y < kImageVerticalVertices; y++) {
        for (int x = 0; x < kImageHorizontalVertices; x++) {
            int positionsIndex = x + (y * (kImageHorizontalVertices + 1));
            int squareIndex = x + (y * kImageHorizontalVertices);
            int vertexIndex = squareIndex * 12; // 12 GLfloats per square
            GLKVector2 position = vertexPositions[positionsIndex];
            GLKVector2 rightPosition = vertexPositions[positionsIndex + 1];
            GLKVector2 downPosition = vertexPositions[positionsIndex + kImageHorizontalVertices + 1];
            GLKVector2 downRight = vertexPositions[positionsIndex + kImageHorizontalVertices + 2];
            GLfloat squareTriangles[] = {
                // triangle #1
                position.x,
                position.y,
                rightPosition.x,
                rightPosition.y,
                downRight.x,
                downRight.y,
                // trianlge #2
                downRight.x,
                downRight.y,
                downPosition.x,
                downPosition.y,
                position.x,
                position.y
            };
            memcpy(&vertexData[vertexIndex], squareTriangles, sizeof(GLfloat) * 12);
        }
    }
}

- (void)applyCentralForces:(NSTimeInterval)delay {
    GLfloat horSpacing = 2 / (GLfloat)kImageHorizontalVertices;
    GLfloat verSpacing = 2 / (GLfloat)kImageVerticalVertices;
    for (int y = 0; y < kImageVerticalVertices + 1; y++) {
        for (int x = 0; x < kImageHorizontalVertices + 1; x++) {
            int squareIndex = x + (y * (kImageHorizontalVertices + 1));
            if (isDragging) {
                if (touchingVertex == squareIndex) continue;
            }
            GLKVector2 position = vertexPositions[squareIndex];
            GLKVector2 initialPosition = vertexBasePositions[squareIndex];
            GLKVector2 velocity = vertexVelocities[squareIndex];
            GLKVector2 force = _node_force(position, initialPosition, 0, 3);
            // apply forces from surrounding nodes
            for (int yTest = y - 1; yTest <= y+1; yTest++) {
                if (yTest < 0 || yTest > kImageVerticalVertices) continue;
                for (int xTest = x - 1; xTest <= x+1; xTest++) {
                    if (xTest == x && yTest == y) continue;
                    
                    if (xTest < 0 || xTest > kImageHorizontalVertices) continue;
                    GLfloat steadyForce = 0;
                    if (yTest != y && xTest != x) {
                        steadyForce = sqrtf(pow(verSpacing, 2) + pow(horSpacing, 2));
                    } else if (yTest != y) {
                        steadyForce = verSpacing;
                    } else {
                        steadyForce = horSpacing;
                    }
                    int nodeIndex = xTest + (yTest * (kImageHorizontalVertices + 1));
                    force = GLKVector2Add(force, _node_force(position, vertexPositions[nodeIndex], steadyForce, 2));
                }
            }
            velocity = GLKVector2Add(velocity, GLKVector2MultiplyScalar(force, delay));
            GLKVector2 dragForce = GLKVector2MultiplyScalar(velocity, -1);
            velocity = GLKVector2Add(velocity, GLKVector2MultiplyScalar(dragForce, delay));
            position = GLKVector2Add(position, GLKVector2MultiplyScalar(velocity, delay));
            vertexVelocities[squareIndex] = velocity;
            vertexPositions[squareIndex] = position;
        }
    }
    [self generateVertexData];
}

#pragma mark - Touches -

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    isDragging = YES;
    GLKVector2 point = [self coordinateForPoint:[[touches anyObject] locationInView:self.view]];
    
    GLfloat currentDistance = 10;
    touchLastPoint = point;
    for (int y = 0; y <= kImageVerticalVertices; y++) {
        for (int x = 0; x <= kImageHorizontalVertices; x++) {
            int squareIndex = x + (y * (kImageHorizontalVertices + 1));
            GLKVector2 vertexPosition = vertexPositions[squareIndex];
            GLfloat distance = GLKVector2Distance(vertexPosition, point);
            if (distance < currentDistance) {
                currentDistance = distance;
                touchingVertex = squareIndex;
            }
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!isDragging) return;
    GLKVector2 point = [self coordinateForPoint:[[touches anyObject] locationInView:self.view]];
    GLKVector2 offset = GLKVector2Subtract(point, touchLastPoint);
    
    GLfloat currentDistance = 10;
    for (int y = 0; y <= kImageVerticalVertices; y++) {
        for (int x = 0; x <= kImageHorizontalVertices; x++) {
            int squareIndex = x + (y * (kImageHorizontalVertices + 1));
            GLKVector2 vertexPosition = vertexBasePositions[squareIndex];
            GLfloat distance = GLKVector2Distance(vertexPosition, point);
            if (distance < currentDistance) {
                currentDistance = distance;
                touchingVertex = squareIndex;
            }
        }
    }
    
    vertexPositions[touchingVertex] = GLKVector2Add(vertexPositions[touchingVertex],
                                                    offset);
    
    touchLastPoint = point;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    isDragging = NO;
}

- (GLKVector2)coordinateForPoint:(CGPoint)p {
    GLKVector2 vector = GLKVector2Make(p.x - windowWidth / 2,
                                       p.y - windowHeight / 2);
    vector.x /= windowWidth / 2;
    vector.y /= -windowWidth / 2;
    return vector;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update {
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    NSDate * now = [NSDate date];
    if (lastAnimation) {
        NSTimeInterval interval = [now timeIntervalSinceDate:lastAnimation];
        [self applyCentralForces:interval];
    }
    lastAnimation = now;

    
    // Render the object with GLKit
    [self.effect prepareToDraw];
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, textureCoords);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertexData);
    glDrawArrays(GL_TRIANGLES, 0, vertexCount);
    glDisableVertexAttribArray(GLKVertexAttribPosition);
}

@end

static GLKVector2 _node_force(GLKVector2 nodePosition, GLKVector2 pullPosition, GLfloat steadyLength, GLfloat coeff) {
    GLKVector2 totalForce = GLKVector2Subtract(pullPosition, nodePosition);
    if (GLKVector2Length(totalForce) == 0) return GLKVector2Make(0, 0);
    GLKVector2 fixedForce = GLKVector2MultiplyScalar(totalForce, steadyLength / GLKVector2Length(totalForce));
    return GLKVector2MultiplyScalar(GLKVector2Subtract(totalForce, fixedForce), coeff);
}
