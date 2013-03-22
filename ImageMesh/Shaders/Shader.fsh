//
//  Shader.fsh
//  ImageMesh
//
//  Created by Alex Nichol on 3/22/13.
//  Copyright (c) 2013 Alex Nichol. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
