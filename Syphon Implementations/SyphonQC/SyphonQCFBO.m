/*
    SyphonQCFBO.m
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

#import "SyphonQCFBO.h"

// macro for speed
#import <OpenGL/CGLMacro.h>

@implementation SyphonQCFBO


- (id) initWithContext:(CGLContextObj)cgl_ctx
{
	if (self = [super init])
	{
	
		context = cgl_ctx;
		CGLRetainContext(context);
				
		// test for FBO support.
		/*	GLint supported;
		 glGetIntegerv(GL_FRAMEBUFFER_EXT, &supported);
		 if(!supported)
		 {
		 CGLUnlockContext(cgl_ctx);
		 NSLog(@"no FBO support...");
		 return nil;
		 }
		 */		
		
		// this pushes texture attributes
		[self pushAttributes:cgl_ctx];
		// since we are using FBOs we ought to keep track of what was previously bound
		[self pushFBO:cgl_ctx];
		
		// faux bounds for now, for testing to init our FBO
		// this also generates our texture for us.
		
		//	[self generateNewTexture];
		
		// init our texture and test to see if we supper
		GLuint textureID;
		glGenTextures(1, &textureID);	
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, textureID);
		
		glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, 640U, 480U, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, NULL);
				
		// Create temporary FBO to render in texture 
		glGenFramebuffersEXT(1, &fboID);
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboID);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_RECTANGLE_ARB, textureID, 0);
		
		GLenum status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
		glDeleteTextures(1, &textureID);
		// restore state
		[self popFBO:cgl_ctx];
		[self popAttributes:cgl_ctx];
		if(status != GL_FRAMEBUFFER_COMPLETE_EXT)
		{	
	//		NSLog(@"Cannot create FBO");
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (void)cleanupGL
{
	CGLContextObj cgl_ctx = context;
	CGLLockContext(cgl_ctx);
	if (fboID) glDeleteFramebuffersEXT(1, &fboID);
	CGLUnlockContext(cgl_ctx);	
	
	CGLReleaseContext(context);
}

- (void) dealloc
{
	[self cleanupGL];
	[super dealloc];
}

- (void)finalize
{
	[self cleanupGL];
	[super finalize];
}

- (void) pushFBO:(CGLContextObj)cgl_ctx
{
//	CGLContextObj cgl_ctx = context;
//	glGetIntegerv(GL_DRAW_BUFFER, &previousDrawBuffer);
//	glGetIntegerv(GL_READ_BUFFER, &previousReadBuffer);
	
	glGetIntegerv(GL_FRAMEBUFFER_BINDING_EXT, &previousFBO);
	glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING_EXT, &previousReadFBO);
	glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING_EXT, &previousDrawFBO);
	
//	NSLog(@"Pushing FBO: previous Draw: %i", previousDrawBuffer);
//	NSLog(@"Pushing FBO: previous Read: %i", previousReadBuffer);
//	NSLog(@"Pushing FBO: previous FBO: %i", previousFBO);
//	NSLog(@"Pushing FBO: previous FBO Draw: %i", previousDrawFBO);
//	NSLog(@"Pushing FBO: previous FBO Read: %i", previousReadFBO);
}

- (void) popFBO:(CGLContextObj)cgl_ctx
{
//	CGLContextObj cgl_ctx = context;
	// pop 
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, previousFBO);	
	glBindFramebufferEXT(GL_READ_FRAMEBUFFER_EXT, previousReadFBO);
	glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, previousDrawFBO);

//	glDrawBuffer(previousDrawBuffer);
//	glReadBuffer(previousReadBuffer);

}

- (void)pushAttributes:(CGLContextObj)cgl_ctx
{
	// save our current GL state - balanced in detachFBO method
	glPushAttrib(GL_ALL_ATTRIB_BITS);
//	glPushClientAttrib(GL_CLIENT_ALL_ATTRIB_BITS);	// We don't do anything to affect this so I'm disabling it, Tom
}

- (void)popAttributes:(CGLContextObj)cgl_ctx
{
	// restore states // assume this is balanced with above 
	glPopAttrib();
//	glPopClientAttrib(); 	// We don't do anything to affect this so I'm disabling it, Tom
}

- (void) attachFBO:(CGLContextObj)cgl_ctx withTexture:(GLuint)tex width:(GLsizei)width height:(GLsizei)height
{
//	CGLContextObj cgl_ctx = context;
	
	// bind our FBO
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboID);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_RECTANGLE_ARB, tex, 0);

	// Assume FBOs JUST WORK, because we checked on startExecution	

	// Setup OpenGL states 
	// this may be an issue... ?
	
	glViewport(0, 0,  width, height);
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	
	glOrtho(0.0, width,  0.0,  height, -1, 1);		
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
			
	// client now renders to our quad...
}

- (void ) detachFBO:(CGLContextObj) cgl_ctx
{
//	CGLContextObj cgl_ctx = context;
	// Restore OpenGL states 
	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
		
	glFlushRenderAPPLE();	// Really don't see why we need this? Tom
}


@end
