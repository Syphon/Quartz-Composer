/*
    SyphonClientQCPlugIn.m
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

#import "SyphonClientQCPlugIn.h"
/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#define	kQCPlugIn_Name				@"Syphon Client"
#define	kQCPlugIn_Description		@"SyphonClientQCPlugIn description"

#if __BIG_ENDIAN__
#define kQCPlugInPixelFormat QCPlugInPixelFormatARGB8
#else
#define kQCPlugInPixelFormat QCPlugInPixelFormatBGRA8			
#endif

static void _TextureReleaseCallback(CGLContextObj cgl_ctx, GLuint name, void* info)
{
	glDeleteTextures(1, &name);
}

@implementation SyphonClientQCPlugIn

@dynamic inputServerName;
@dynamic inputServerApp;
@dynamic outputImage;

+ (NSDictionary*) attributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	if([key isEqualToString:@"inputServerName"])
	   return [NSDictionary dictionaryWithObject:@"Server Name" forKey:QCPortAttributeNameKey];
	
	if([key isEqualToString:@"inputServerApp"])
		return [NSDictionary dictionaryWithObject:@"Application Name" forKey:QCPortAttributeNameKey]; 

	if([key isEqualToString:@"outputImage"])
		return [NSDictionary dictionaryWithObject:@"Image" forKey:QCPortAttributeNameKey]; 

	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode) timeMode
{	
	return kQCPlugInTimeModeTimeBase;
}

- (id) init
{
	if((self = [super init]))
	{
		clearedOutput = YES;
	}
	return self;
}

/*
- (void) finalize
{	
	[super finalize];
}
*/

- (void) dealloc
{
	[syClient release];
	[clientFBO release];
	[super dealloc];
}

@end

@implementation SyphonClientQCPlugIn (Execution)

- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	syClient = [[SyphonNameboundClient alloc] init];
	// make FBO for persistant, unique image output
	CGLContextObj cgl_ctx = [context CGLContextObj];
	
	clientFBO = [[SyphonQCFBO alloc] initWithContext:cgl_ctx];
	if(clientFBO == nil)
	{
		[context logMessage:@"Cannot create FBO"];
		return NO;
	}
	
	return YES;
}

/*
- (void) enableExecution:(id<QCPlugInContext>)context
{
 
}
*/

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	if([self didValueForInputKeyChange:@"inputServerName"])
	{
		[syClient setName:self.inputServerName];
	}
	if ([self didValueForInputKeyChange:@"inputServerApp"])
	{
		[syClient setAppName:self.inputServerApp];
	}
	
	// render whatever we have
	CGLContextObj cgl_ctx = [context CGLContextObj];
	
	[syClient lockClient];
	SyphonClient *client = [syClient client];
	if([client hasNewFrame])
	{
		GLuint texture;

        glPushAttrib(GL_ALL_ATTRIB_BITS);
        glPushClientAttrib(GL_CLIENT_ALL_ATTRIB_BITS); // for vertex arrays

		SyphonImage* latestImage = [client newFrameImageForContext:cgl_ctx];
		NSSize texSize = [latestImage textureSize];
		
		if(!NSEqualSizes(NSZeroSize, texSize))
		{

            // new texture
            glGenTextures(1, &texture);
            glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texture);
            glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, texSize.width, texSize.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, NULL);

			// this must be called before any other FBO stuff can happen for 10.6
			[clientFBO pushFBO:cgl_ctx];
			[clientFBO attachFBO:cgl_ctx withTexture:texture width:texSize.width height:texSize.height];
			
			glColor4f(1.0, 1.0, 1.0, 1.0);
			
			if (latestImage)
			{
				glActiveTexture(GL_TEXTURE0);
				glEnable(GL_TEXTURE_RECTANGLE_EXT);
				glBindTexture(GL_TEXTURE_RECTANGLE_EXT, [latestImage textureName]);
				
				// do not need blending if we use black border for alpha and replace env mode, saves a buffer wipe
				// we can do this since our image draws over the complete surface of the FBO, no pixel goes untouched.
				glDisable(GL_BLEND);
				glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);	
				
				// VA for rendering
				GLfloat tex_coords[] = 
				{
					texSize.width,texSize.height,
					0.0,texSize.height,
					0.0,0.0,
					texSize.width,0.0
				};
				
				GLfloat verts[] = 
				{
					texSize.width,texSize.height,
					0.0,texSize.height,
					0.0,0.0,
					texSize.width,0.0
				};
				
				glEnableClientState( GL_TEXTURE_COORD_ARRAY );
				glTexCoordPointer(2, GL_FLOAT, 0, tex_coords );
				glEnableClientState(GL_VERTEX_ARRAY);		
				glVertexPointer(2, GL_FLOAT, 0, verts );
				glDrawArrays( GL_TRIANGLE_FAN, 0, 4 );	// TODO: GL_QUADS or GL_TRIANGLE_FAN?
				
				glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
			}
			[clientFBO detachFBO:cgl_ctx];
			[clientFBO popFBO:cgl_ctx];
            
            if(texture != 0)
            {
                self.outputImage = [context outputImageProviderFromTextureWithPixelFormat:kQCPlugInPixelFormat
                                                                               pixelsWide:texSize.width
                                                                               pixelsHigh:texSize.height
                                                                                     name:texture
                                                                                  flipped:NO
                                                                          releaseCallback:_TextureReleaseCallback
                                                                           releaseContext:NULL
                                                                               colorSpace:[context colorSpace]
                                                                         shouldColorMatch:YES];
                
                clearedOutput = NO;
            }
		}

        glPopClientAttrib();
        glPopAttrib();
        

		[latestImage release];
    }
	else if (client == nil && clearedOutput == NO)
	{
		self.outputImage = nil;
		clearedOutput = YES;
	}
	[syClient unlockClient];
	return YES;
}

/*
- (void) disableExecution:(id<QCPlugInContext>)context
{

}
*/

- (void) stopExecution:(id<QCPlugInContext>)context
{
	[clientFBO release];
	clientFBO = nil;
	[syClient release];
	syClient = nil;
}

@end
