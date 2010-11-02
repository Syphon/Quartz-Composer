/*
    SyphonServerListQCPlugIn.h
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

#import "SyphonServerListQCPlugIn.h"

#define	kQCPlugIn_Name				@"Syphon Server List"
#define	kQCPlugIn_Description		@"Lists available Syphon Servers, for use with the Syphon Client patch."

@implementation SyphonServerListQCPlugIn

@dynamic outputServers;

@synthesize needsUpdate = _needsUpdate;

+ (NSDictionary*) attributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	if([key isEqualToString:@"outputServers"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Servers", QCPortAttributeNameKey, nil];
		
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode) timeMode
{
	return kQCPlugInTimeModeIdle;
}

/*
- (id) init
{
	if(self = [super init])
	{

	}
	return self;
}


- (void) finalize
{	
	[super finalize];
}

- (void) dealloc
{
	[super dealloc];
}
*/

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"servers"])
	{
		self.needsUpdate = YES;
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end

@implementation SyphonServerListQCPlugIn (Execution)

- (BOOL) startExecution:(id<QCPlugInContext>)context
{	
	[[SyphonServerDirectory sharedDirectory] addObserver:self forKeyPath:@"servers" options:0 context:nil];
	self.needsUpdate = YES;
	return YES;
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	if (self.needsUpdate)
	{
		self.needsUpdate = NO;
		NSArray *servers = [[SyphonServerDirectory sharedDirectory] servers];
		NSMutableArray *output = [NSMutableArray arrayWithCapacity:[servers count]];
		for (NSDictionary *description in servers)
		{
			NSDictionary *simple = [NSDictionary dictionaryWithObjectsAndKeys:[description objectForKey:SyphonServerDescriptionNameKey], @"Name",
									[description objectForKey:SyphonServerDescriptionAppNameKey], @"App Name", nil];
			[output addObject:simple];
		}
		self.outputServers = output;
	}
	return YES;
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	[[SyphonServerDirectory sharedDirectory] removeObserver:self forKeyPath:@"servers"];
}
@end
