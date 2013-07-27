/*
    SyphonQCFBO.h
	SyphonQC
	
    Copyright 2010 bangnoise (Tom Butterworth) & vade (Anton Marini).
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>
#import	<OpenGL/OpenGL.h>

@interface SyphonQCFBO : NSObject
{
	CGLContextObj context; // cache our context for speed
	
	GLuint fboID; // our FBO
		
	GLint previousDrawBuffer;	// GL_FRONT or GL_BACK
	GLint previousReadBuffer;
	
	GLint previousFBO;	// make sure we pop out to the right FBO
	GLint previousReadFBO;
	GLint previousDrawFBO;
}
- (id) initWithContext:(CGLContextObj)ctx;

// handles current fbo binding, read and write fbo binding state.
- (void) pushFBO:(CGLContextObj)cgl_ctx;
- (void) popFBO:(CGLContextObj)cgl_ctx;
// pushes/pops client and gl attributes
- (void)pushAttributes:(CGLContextObj)cgl_ctx;
- (void)popAttributes:(CGLContextObj)cgl_ctx;
//  attach our FBO, set up the RTT target based on image bounds, and set up GL state for RTT
- (void) attachFBO:(CGLContextObj)cgl_ctx withTexture:(GLuint)tex width:(GLsizei)width height:(GLsizei)height;

- (void) detachFBO:(CGLContextObj)cgl_ctx;

@end

