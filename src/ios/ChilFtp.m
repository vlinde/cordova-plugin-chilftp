#import "ChilFtp.h"

CkoFtp2 *ftp = nil;

@implementation ChilFtp

- (void)keySetting:(CDVInvokedUrlCommand *)command {

    CDVPluginResult *result = nil;
    @try {
        ftp = [[CkoFtp2 alloc] init];


        NSString *key = [[command arguments] objectAtIndex:0];

        if (key == nil || [key isEqual:@"null"] || [key isEqual:@""]) {
            key = @"Anything for 30-day trial";
        }

        BOOL success;

        //  Any string unlocks the component for the 1st 30-days.
        success = [ftp UnlockComponent:key];
        // success
        if (success == YES) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                       messageAsString:@"true"];
        }
            // failure
        else {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"false"];
        }
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    @catch (NSException *e) {
        NSLog(@"Exception: %@", e);
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                   messageAsString:@"false"];
    }
}

- (void)connect:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = nil;

        @try {
            NSString *host = [[command arguments] objectAtIndex:0];
            NSNumber *port = [[command arguments] objectAtIndex:1];
            NSString *user = [[command arguments] objectAtIndex:2];
            NSString *pw = [[command arguments] objectAtIndex:3];
            NSString *restartNext = [[command arguments] objectAtIndex:4];
            NSLog(@"%@ %@ %@ %@ %@", host, port, user, pw, @" Login data for ftp!");

            NSNumber *timeout = [NSNumber numberWithInt:3];

            ftp.Hostname = host;
            ftp.Port = port;
            ftp.Username = user;
            ftp.Password = pw;
            ftp.ConnectTimeout = timeout;

            BOOL success;

            //  Any string unlocks the component for the 1st 30-days.
            success = [ftp Connect];
            // success
            if (success == YES) {
                NSLog(@"%@", @"Connected with success to ftp!!!");


                ftp.RestartNext = [restartNext isEqual:@"true"] ? YES : NO;
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                           messageAsString:@"true"];
            } else {
                NSLog(@"%@", @"Problem with ftp connection!!!");
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                           messageAsString:@"false"];
            }

            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        @catch (NSException *exception) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error when trying to connect"];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }

    }];
}

- (void)asyncPutFile:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = nil;
        @try {
            NSString *localFile = [[command arguments] objectAtIndex:0];
            NSString *remoteFile = [[command arguments] objectAtIndex:1];

            BOOL success;

            success = [ftp AsyncPutFileStart:localFile
                              remoteFilename:remoteFile];

            if (success != YES) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                           messageAsString:@"false"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }


            int fileSize = 0;
            NSString *sendData = nil;

            while (ftp.AsyncFinished != YES) {
                NSLog(@"%d%@", [ftp.AsyncBytesSent intValue], @"bytes send");
                NSLog(@"%d%@", [ftp.UploadTransferRate intValue], @"bytes send");
                NSLog(@"%d%@", fileSize, @" - fileSize");
                sendData = [NSString stringWithFormat:@"{\"sendByte\":\"%d\", \"transferRate\":\"%d\"}", [ftp.AsyncBytesSent intValue], [ftp.UploadTransferRate intValue]];

                if ([ftp.AsyncBytesSent intValue] > 0 && fileSize == [ftp.AsyncBytesSent intValue]) {
                    sendData = [NSString stringWithFormat:@"{\"value\":\"%@\"}", ftp.AsyncSuccess ? @"true" : @"false"];

                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"%@", sendData]];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

                    [ftp Disconnect];
                    return;
                } else {
                    NSLog(@"%@%@", sendData, @" - sendData");
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@", sendData]];
                    [result setKeepCallback:[NSNumber numberWithBool:YES]];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

                    fileSize = [ftp.AsyncBytesSent intValue];

                    [ftp SleepMs:[NSNumber numberWithInt:1000]];
                }
            }
            if (ftp.AsyncSuccess == YES) {
                sendData = [NSString stringWithFormat:@"{\"value\":\"%@\"}", ftp.AsyncSuccess ? @"true" : @"false"];
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@", sendData]];
                [result setKeepCallback:[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

                NSLog(@"%@", @"File Uploaded");
            } else {
                sendData = [NSString stringWithFormat:@"{\"value\":\"%@\"}", ftp.AsyncSuccess ? @"true" : @"false"];

                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"%@", sendData]];
                [result setKeepCallbackAsBool:YES];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

                NSLog(@"%@", ftp.AsyncLog);
            }
        }
        @catch (NSException *e) {
            NSLog(@"Exception: %@", e);
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"false"];
        }
    }];
}

- (void)asyncGetFile:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = nil;
        @try {
            NSString *remoteFile = [[command arguments] objectAtIndex:0];
            NSString *localFile = [[command arguments] objectAtIndex:1];

            BOOL success;

            success = [ftp AsyncGetFileStart:remoteFile
                               localFilename:localFile];

            if (success != YES) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                           messageAsString:@"false"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }


            int fileSize = 0;
            NSString *receivedData = nil;

            while (ftp.AsyncFinished != YES) {
                NSLog(@"%d%@", [ftp.AsyncBytesReceived intValue], @"bytes received");
                NSLog(@"%d%@", [ftp.DownloadTransferRate intValue], @"bytes received");
                NSLog(@"%d%@", fileSize, @" - fileSize");
                receivedData = [NSString stringWithFormat:@"{\"receivedByte\":\"%d\", \"transferRate\":\"%d\"}", [ftp.AsyncBytesReceived intValue], [ftp.DownloadTransferRate intValue]];

                if ([ftp.AsyncBytesReceived intValue] > 0 && fileSize == [ftp.AsyncBytesReceived intValue]) {
                    receivedData = [NSString stringWithFormat:@"{\"value\":\"%@\"}", ftp.AsyncSuccess ? @"true" : @"false"];

                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"%@", receivedData]];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

                    [ftp Disconnect];
                    return;
                } else {
                    NSLog(@"%@%@", receivedData, @" - receivedData");
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@", receivedData]];
                    [result setKeepCallback:[NSNumber numberWithBool:YES]];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

                    fileSize = [ftp.AsyncBytesReceived intValue];

                    [ftp SleepMs:[NSNumber numberWithInt:1000]];
                }
            }
            if (ftp.AsyncSuccess == YES) {
                receivedData = [NSString stringWithFormat:@"{\"value\":\"%@\"}", ftp.AsyncSuccess ? @"true" : @"false"];
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@", receivedData]];
                [result setKeepCallback:[NSNumber numberWithBool:YES]];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

                NSLog(@"%@", @"File Downloaded");
            } else {
                receivedData = [NSString stringWithFormat:@"{\"value\":\"%@\"}", ftp.AsyncSuccess ? @"true" : @"false"];

                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"%@", receivedData]];
                [result setKeepCallbackAsBool:YES];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

                NSLog(@"%@", ftp.AsyncLog);
            }
        }
        @catch (NSException *e) {
            NSLog(@"Exception: %@", e);
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"false"];
        }
    }];
}

- (void)download:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = nil;

        @try {
            NSString *remoteFile = [[command arguments] objectAtIndex:0];
            NSString *localFile = [[command arguments] objectAtIndex:1];

            if ([localFile length] == 0 || [remoteFile length] == 0) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Expected localFile and remoteFile."];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {

                NSRange needleRangeRemote = [remoteFile rangeOfString:@"/" options:NSBackwardsSearch];
                NSRange needleRangeRemoteFilePath = NSMakeRange(0, needleRangeRemote.location + 1);
                NSRange needleRangeRemoteFileName = NSMakeRange(needleRangeRemote.location + 1, [remoteFile length] - (needleRangeRemote.length + needleRangeRemote.location));

                NSString *remoteFileName = [remoteFile substringWithRange:needleRangeRemoteFileName];
                NSString *remoteFilePath = [remoteFile substringWithRange:needleRangeRemoteFilePath];

                BOOL changed = [ftp ChangeRemoteDir:remoteFilePath];
                if (!changed) {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Remote dir cannot be changed!"];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                }

                BOOL success;
                success = [ftp GetFile:remoteFileName localPath:localFile];

                if (success != YES) {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"false"];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                } else {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"true"];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                }
            }
        }
        @catch (NSException *exception) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error when trying to download"];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }

    }];
}

- (void)upload:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = nil;

        @try {
            NSString *localFile = [[command arguments] objectAtIndex:0];
            NSString *remoteFile = [[command arguments] objectAtIndex:1];

            if ([localFile length] == 0 || [remoteFile length] == 0) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Expected localFile and remoteFile."];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {

                NSRange needleRangeRemote = [remoteFile rangeOfString:@"/" options:NSBackwardsSearch];

                NSRange needleRangeRemoteFilePath = NSMakeRange(0, needleRangeRemote.location + 1);
                NSRange needleRangeRemoteFileName = NSMakeRange(needleRangeRemote.location + 1, [remoteFile length] - (needleRangeRemote.length + needleRangeRemote.location));

                NSString *remoteFileName = [remoteFile substringWithRange:needleRangeRemoteFileName];
                NSString *remoteFilePath = [remoteFile substringWithRange:needleRangeRemoteFilePath];

                BOOL changed = [ftp ChangeRemoteDir:remoteFilePath];
                if (!changed) {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Remote dir cannot be changed!"];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                }

                BOOL success;
                success = [ftp PutFile:localFile remoteFilename:remoteFileName];

                if (success != YES) {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"false"];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                } else {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"true"];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                }
            }
        }
        @catch (NSException *exception) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error when trying to upload"];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    }];
}

- (void)rename:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = nil;

        @try {
            NSString *remotePath = [[command arguments] objectAtIndex:0];
            NSString *existingFileName = [[command arguments] objectAtIndex:1];
            NSString *newFileName = [[command arguments] objectAtIndex:2];
            NSString *replaceString = [[command arguments] objectAtIndex:3];

            BOOL replace = [replaceString isEqual:@"true"] ? YES : NO;
            if ([remotePath length] == 0 || [existingFileName length] == 0 || [newFileName length] == 0) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"All fields are required."];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {

                BOOL changed = [ftp ChangeRemoteDir:remotePath];
                if (!changed) {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Remote dir cannot be changed!"];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                }

                BOOL success;
                BOOL success_remove;
                success = [ftp RenameRemoteFile:existingFileName newFilename:newFileName];

                if (success != YES && replace == YES) {
                    success_remove = [ftp DeleteRemoteFile:newFileName];
                    if(success_remove != YES){
                        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"false"];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                    } else {
                        success = [ftp RenameRemoteFile:existingFileName newFilename:newFileName];
                        if (success != YES) {
                            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"false"];
                            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                        }
                    }
                } else if(success != YES){
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"false"];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                } else {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"true"];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                }
            }
        }
        @catch (NSException *exception) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error when trying to rename the file"];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    }];
}

- (void)ls:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = nil;

        @try {
            NSString *remoteDir = [[command arguments] objectAtIndex:0];

            if (remoteDir == nil) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Expected path."];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {
                if ([remoteDir characterAtIndex:remoteDir.length - 1] != '/') {
                    remoteDir = [remoteDir stringByAppendingString:@"/"];
                }

                int i;
                int n;

                BOOL changed = [ftp ChangeRemoteDir:remoteDir];

                if (!changed) {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Remote dir cannot be changed!"];
                    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                }

                n = [[ftp GetDirCount] intValue];
                if (n < 0) {
                    NSLog(@"%@", ftp.LastErrorText);
                    return;
                }

                NSMutableArray *newFilesInfo = [[NSMutableArray alloc] init];
                if (n > 0) {

                    BOOL isDir = NO;
                    BOOL isFile = NO;

                    for (i = 0; i <= n - 1; i++) {
                        if ([ftp GetIsDirectory:[NSNumber numberWithInt:i]] == YES) {
                            isDir = YES;
                            isFile = NO;
                        } else {
                            isDir = NO;
                            isFile = YES;
                        }

                        NSMutableDictionary *newFile = [[NSMutableDictionary alloc] init];

                        NSString *name = [ftp GetFilename:[NSNumber numberWithInt:i]];
                        NSNumber *size = [ftp GetSize:[NSNumber numberWithInt:i]];

                        NSString *isDirString = isDir ? @"true" : @"false";
                        NSString *isFileDir = isFile ? @"true" : @"false";

                        [newFile setObject:name forKey:@"name"];
                        [newFile setObject:size forKey:@"size"];
                        [newFile setObject:isDirString forKey:@"isDir"];
                        [newFile setObject:isFileDir forKey:@"isFile"];
                        [newFilesInfo addObject:newFile];
                    }
                }

                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:newFilesInfo];
                [result setKeepCallback:[NSNumber numberWithBool:NO]];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

            }
        }
        @catch (NSException *exception) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error when trying to list directory content"];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    }];
}

- (void)getRemoteFileSize:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = nil;
        @try {
            NSString *file = [[command arguments] objectAtIndex:0];

            NSNumber *fileSize = [ftp GetSizeByName:file];
            if ([fileSize intValue] > 0) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%d", [fileSize intValue]]];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"%@", ftp.LastErrorText]];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
        }
        @catch (NSException *e) {
            NSLog(@"Exception: %@", e);
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"Error when trying to get remote file size"];
        }
    }];
}

- (void)createRemoteDir:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = nil;
        @try {
            NSString *folder = [[command arguments] objectAtIndex:0];

            BOOL created = [ftp CreateRemoteDir:folder];

            if (created) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"true"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"false"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
        }
        @catch (NSException *e) {
            NSLog(@"Exception: %@", e);
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"Error when trying to create remote directory"];
        }
    }];
}

- (void)changeRemoteDir:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = nil;
        @try {
            NSString *folder = [[command arguments] objectAtIndex:0];

            BOOL changed = [ftp ChangeRemoteDir:folder];

            if (changed) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"true"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"false"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
        }
        @catch (NSException *e) {
            NSLog(@"Exception: %@", e);
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"Error when trying to change remote directory"];
        }
    }];
}

- (void)deleteRemoteFile:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = nil;
        @try {
            NSString *file = [[command arguments] objectAtIndex:0];

            BOOL changed = [ftp DeleteRemoteFile:file];

            if (changed) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"true"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"false"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
        }
        @catch (NSException *e) {
            NSLog(@"Exception: %@", e);
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"Error when trying to delete remote directory"];
        }
    }];
}

- (void)getPathFromMediaUri:(CDVInvokedUrlCommand *)command {
//    CDVPluginResult *result = nil;


}

- (void)abort:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        [ftp AsyncAbort];
    }];
}

- (void)disconnect:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *result = nil;
        @try {

            BOOL disconnected = [ftp Disconnect];

            if (disconnected) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"true"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            } else {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"false"];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
        }
        @catch (NSException *e) {
            NSLog(@"Exception: %@", e);
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"Error when trying to disconnect"];
        }
    }];
}

@end
