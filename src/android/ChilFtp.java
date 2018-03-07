package com.vlinde.cordova.plugin.chilftp;

import com.chilkatsoft.*;

import org.apache.cordova.*;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;
import android.provider.MediaStore;
import android.content.CursorLoader;
import android.util.Log;
import android.database.Cursor;
import android.net.Uri;

public class ChilFtp extends CordovaPlugin {

    private static final String TAG = "ChilFtp";
    private CkFtp2 ftp = new CkFtp2();

    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
    }

    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) throws JSONException {
        PluginResult.Status status = PluginResult.Status.OK;

        try {
            if (action.equals("keySetting")) {
                keySetting(data.getString(0), callbackContext);
            } else if (action.equals("connect")) {
                connect(data.getString(0), data.getString(1), data.getString(2), data.getString(3), data.getBoolean(4), callbackContext);
            } else if (action.equals("asyncPutFile")) {
                asyncPutFile(data.getString(0), data.getString(1), callbackContext);
            } else if (action.equals("upload")) {
                upload(data.getString(0), data.getString(1), callbackContext);
            } else if (action.equals("asyncGetFile")) {
                asyncGetFile(data.getString(0), data.getString(1), callbackContext);
            } else if (action.equals("download")) {
                download(data.getString(0), data.getString(1), callbackContext);
            } else if (action.equals("rename")) {
                rename(data.getString(0), data.getString(1), data.getString(2), callbackContext);
            } else if (action.equals("ls")) {
                ls(data.getString(0), callbackContext);
            } else if (action.equals("getRemoteFileSize")) {
                getRemoteFileSize(data.getString(0), callbackContext);
            } else if (action.equals("createRemoteDir")) {
                createRemoteDir(data.getString(0), callbackContext);
            } else if (action.equals("changeRemoteDir")) {
                changeRemoteDir(data.getString(0), callbackContext);
            } else if (action.equals("deleteRemoteFile")) {
                deleteRemoteFile(data.getString(0), callbackContext);
            } else if (action.equals("disconnect")) {
                disconnect(callbackContext);
            } else if (action.equals("abort")) {
                asyncAbort();
            } else if (action.equals("getPathFromMediaUri")) {
                getPathFromMediaUri(data.getString(0), callbackContext);
            }

        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
        }

        return true;
    }

    public void keySetting(String key, CallbackContext callbackContext) {
        boolean success;

        if (key != null) {
            //  Any string unlocks the component for the 1st 30-days.
            key = "Anything for 30-day trial";
        }
        success = ftp.UnlockComponent(key);
        if (success != true) {
            callbackContext.error(String.valueOf(success));
        } else {
            callbackContext.success(String.valueOf(success));
        }
    }

    public void connect(String host, String port, String user, String password, boolean restartNext, CallbackContext callbackContext) {
        boolean success;

        ftp.put_Hostname(host);
        ftp.put_Username(user);
        ftp.put_Password(password);
        ftp.put_Port(Integer.parseInt(port));
        ftp.put_ConnectTimeout(3);

        ftp.put_Passive(true);

        success = ftp.Connect();


        int failReason = ftp.get_ConnectFailReason();
        //  The possible failure reasons are:
        //  0 = success
        //  Non-SSL socket fail reasons:
        //   1 = empty hostname
        //   2 = DNS lookup failed
        //   3 = DNS timeout
        //   4 = Aborted by application.
        //   5 = Internal failure.
        //   6 = Connect Timed Out
        //   7 = Connect Rejected (or failed for some other reason)
        //  SSL failure reasons:
        //   100 = Internal schannel error
        //   101 = Failed to create credentials
        //   102 = Failed to send initial message to proxy.
        //   103 = Handshake failed.
        //   104 = Failed to obtain remote certificate.
        //  300 = asynch op in progress
        //  301 = login failure.
        //
        if (success != true) {
            callbackContext.error("connect fail reason = " + String.valueOf(failReason));
            Log.i(TAG, ftp.lastErrorText());
        } else {
            ftp.put_RestartNext(restartNext);
            callbackContext.success("connect success reason = " + String.valueOf(failReason));
        }

    }

    public void asyncAbort() {
        ftp.AsyncAbort();
        Log.i(TAG, ftp.lastErrorText());
    }

    public void disconnect(final CallbackContext callbackContext) {
        try {
            ftp.Disconnect();
            Log.i(TAG, ftp.lastErrorText());

            JSONObject result = new JSONObject();
            result.put("success", true);
            callbackContext.success(result);

        } catch (JSONException e) {

        }
    }

    public void asyncPutFile(String localFileName, String remoteFileName, final CallbackContext callbackContext) {
        boolean success;

        success = ftp.AsyncPutFileStart(localFileName, remoteFileName);
        if (success != true) {
            callbackContext.error(ftp.lastErrorText());
            Log.i(TAG, ftp.lastErrorText());
            return;
        }
        //  The application is now free to do anything else
        //  while the file is uploading.
        //  For this example, we'll simply sleep and periodically
        //  check to see if the transfer if finished.  While checking
        //  however, we'll report on the progress in both number
        //  of bytes tranferred and performance in bytes/second.

        this.cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    long fileSize = 0;
                    JSONObject result = new JSONObject();

                    while (ftp.get_AsyncFinished() != true) {
                        Log.i(TAG, String.valueOf(ftp.get_AsyncBytesSent()) + " bytes sent");
                        Log.i(TAG, String.valueOf(ftp.get_UploadTransferRate()) + " bytes per second");

                        result.put("sendByte", String.valueOf(ftp.get_AsyncBytesSent()));
                        result.put("transferRate", String.valueOf(ftp.get_UploadTransferRate()));


                        if (ftp.get_AsyncBytesSent() > 0 && fileSize == ftp.get_AsyncBytesSent()) {
                            result = new JSONObject();
                            result.put("value", String.valueOf(ftp.get_AsyncSuccess()));
                            result.put("log", ftp.asyncLog());
                            callbackContext.error(result);

                            Log.i(TAG, result.toString());
                            ftp.Disconnect();
                            return;
                        } else {

                            PluginResult progressResult = new PluginResult(PluginResult.Status.OK, result);
                            progressResult.setKeepCallback(true);
                            callbackContext.sendPluginResult(progressResult);

                            fileSize = ftp.get_AsyncBytesSent();

                            //  Sleep 1 second.
                            ftp.SleepMs(1000);
                        }
                    }

                    //  Did the upload succeed?
                    if (ftp.get_AsyncSuccess() == true) {
                        result = new JSONObject();
                        result.put("value", String.valueOf(ftp.get_AsyncSuccess()));
                        result.put("log", ftp.asyncLog());
                        callbackContext.success(result);

                        Log.i(TAG, "File Uploaded!");
                    } else {
                        //  The error information for asynchronous ops
                        //  is in AsyncLog as opposed to LastErrorText
                        result = new JSONObject();
                        result.put("value", String.valueOf(ftp.get_AsyncSuccess()));
                        result.put("log", ftp.asyncLog());
                        callbackContext.error(result);
                        Log.i(TAG, ftp.asyncLog());
                    }
                } catch (JSONException e) {

                }
            }
        });

    }

    public void upload(String localFile, String remoteFile, final CallbackContext callbackContext) {
        boolean success;


        if (localFile == null || remoteFile == null) {
            callbackContext.error("Expected localFile and remoteFile.");
        } else {
            String remoteFilePath = remoteFile.substring(0, remoteFile.lastIndexOf('/') + 1);
            String remoteFileName = remoteFile.substring(remoteFile.lastIndexOf('/') + 1);
            String localFilePath = localFile.substring(0, localFile.lastIndexOf('/') + 1);
            String localFileName = localFile.substring(localFile.lastIndexOf('/') + 1);

            ftp.ChangeRemoteDir(remoteFilePath);
            success = ftp.PutFile(localFile, remoteFileName);
            if (success != true) {
                callbackContext.error(ftp.lastErrorText());
                Log.i(TAG, ftp.lastErrorText());
                return;
            }
            try {
                JSONObject result = new JSONObject();
                result.put("success", success);
                callbackContext.success(result);
            } catch (JSONException e) {
            }
        }
    }

    public void asyncGetFile(String remoteFileName, String localFileName, final CallbackContext callbackContext) {
        boolean success;

        success = ftp.AsyncGetFileStart(remoteFileName, localFileName);
        if (success != true) {
            callbackContext.error(ftp.lastErrorText());
            Log.i(TAG, ftp.lastErrorText());
            return;
        }
        //  The application is now free to do anything else
        //  while the file is uploading.
        //  For this example, we'll simply sleep and periodically
        //  check to see if the transfer if finished.  While checking
        //  however, we'll report on the progress in both number
        //  of bytes tranferred and performance in bytes/second.

        this.cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    long fileSize = 0;
                    JSONObject result = new JSONObject();

                    while (ftp.get_AsyncFinished() != true) {
                        Log.i(TAG, String.valueOf(ftp.get_AsyncBytesReceived()) + " bytes sent");
                        Log.i(TAG, String.valueOf(ftp.get_DownloadTransferRate()) + " bytes per second");

                        result.put("sendByte", String.valueOf(ftp.get_AsyncBytesSent()));
                        result.put("transferRate", String.valueOf(ftp.get_DownloadTransferRate()));


                        if (ftp.get_AsyncBytesReceived() > 0 && fileSize == ftp.get_AsyncBytesReceived()) {
                            result = new JSONObject();
                            result.put("value", String.valueOf(ftp.get_AsyncSuccess()));
                            result.put("log", ftp.asyncLog());
                            callbackContext.error(result);

                            Log.i(TAG, result.toString());
                            ftp.Disconnect();
                            return;
                        } else {

                            PluginResult progressResult = new PluginResult(PluginResult.Status.OK, result);
                            progressResult.setKeepCallback(true);
                            callbackContext.sendPluginResult(progressResult);

                            fileSize = ftp.get_AsyncBytesReceived();

                            //  Sleep 1 second.
                            ftp.SleepMs(1000);
                        }
                    }

                    //  Did the upload succeed?
                    if (ftp.get_AsyncSuccess() == true) {
                        result = new JSONObject();
                        result.put("value", String.valueOf(ftp.get_AsyncSuccess()));
                        result.put("log", ftp.asyncLog());
                        callbackContext.success(result);

                        Log.i(TAG, "File Uploaded!");
                    } else {
                        //  The error information for asynchronous ops
                        //  is in AsyncLog as opposed to LastErrorText
                        result = new JSONObject();
                        result.put("value", String.valueOf(ftp.get_AsyncSuccess()));
                        result.put("log", ftp.asyncLog());
                        callbackContext.error(result);
                        Log.i(TAG, ftp.asyncLog());
                    }
                } catch (JSONException e) {

                }
            }
        });

    }

    public void download(String remoteFile, String localFile, final CallbackContext callbackContext) {
        boolean success;

        if (localFile == null || remoteFile == null) {
            callbackContext.error("Expected localFile and remoteFile.");
        } else {

            String remoteFilePath = remoteFile.substring(0, remoteFile.lastIndexOf('/') + 1);
            String remoteFileName = remoteFile.substring(remoteFile.lastIndexOf('/') + 1);
            String localFilePath = localFile.substring(0, localFile.lastIndexOf('/') + 1);
            String localFileName = localFile.substring(localFile.lastIndexOf('/') + 1);


            ftp.ChangeRemoteDir(remoteFilePath);

            success = ftp.GetFile(remoteFileName, localFile);
            if (success != true) {
                callbackContext.error(ftp.lastErrorText());
                Log.i(TAG, ftp.lastErrorText());
                return;
            }
            try {
                JSONObject result = new JSONObject();
                result.put("success", success);
                callbackContext.success(result);
            } catch (JSONException e) {
            }

        }
    }

    public void rename(String remotePath, String existingFileName, String newFileName, final CallbackContext callbackContext) {
        boolean success;

        if (remotePath == null || existingFileName == null || newFileName == null) {
            callbackContext.error("All fields are required.");
        } else {

            ftp.ChangeRemoteDir(remotePath);

            success = ftp.RenameRemoteFile(existingFileName, newFileName);
            if (success != true) {
                callbackContext.error(ftp.lastErrorText());
                Log.i(TAG, ftp.lastErrorText());
                return;
            }
            try {
                JSONObject result = new JSONObject();
                result.put("success", success);
                callbackContext.success(result);
            } catch (JSONException e) {
            }
        }
    }

    public void ls(String remoteDir, final CallbackContext callbackContext) {

        //  The ListPattern property is our directory listing filter.
        //  The default value is "*", which includes everything.
//        System.out.println(ftp.listPattern());
        if (remoteDir == null) {
            callbackContext.error("Expected path.");
        } else {
            if (!remoteDir.endsWith("/")) {
                remoteDir = remoteDir.concat("/");
            }

            try {
                JSONArray fileList = new JSONArray();
                JSONObject result = new JSONObject();
                //  To get file and sub-directory information, simply
                //  loop from 0 to ftp.GetDirCount() - 1
                int i;
                int n;

                boolean changed = ftp.ChangeRemoteDir(remoteDir);
                if (!changed) {
                    callbackContext.error("Remote dir cannot be changed!");
                    Log.i(TAG, ftp.lastErrorText());
                }

                n = ftp.GetDirCount();
                if (n < 0) {
                    System.out.println(ftp.lastErrorText());
                    return;
                }
                if (n > 0) {
                    for (i = 0; i <= n - 1; i++) {
                        result = new JSONObject();
                        result.put("name", ftp.getFilename(i));
                        result.put("size", ftp.GetSize(i)); // (in bytes)
//                        result.put("modifiedDate", ftp.CkFtp2_getLastModifiedTime(i));

                        //  Is this a sub-directory?
                        if (ftp.GetIsDirectory(i) == true) {
                            result.put("isFile", false);
                            result.put("isDir", true);
                        } else {
                            result.put("isFile", true);
                            result.put("isDir", false);
                        }

                        fileList.put(result);
                    }

                }

                callbackContext.success(fileList);

            } catch (JSONException e) {
            }
        }
    }

    public void createRemoteDir(String newRemoteDir, CallbackContext callbackContext) {
        boolean created = ftp.CreateRemoteDir(newRemoteDir);

        if (created) {
            callbackContext.success(String.valueOf(created));
            Log.i(TAG, "Create New Directory!");
        } else {
            callbackContext.error(String.valueOf(created));
            Log.i(TAG, ftp.lastErrorText());
        }
    }

    public void getRemoteFileSize(String remoteFilename, CallbackContext callbackContext) {
        int fileSize = ftp.GetSizeByName(remoteFilename);

        if (fileSize > 0) {
            callbackContext.success(fileSize);
            Log.i(TAG, "get file size!");
        } else {
            callbackContext.error(fileSize);
            Log.i(TAG, ftp.lastErrorText());
        }
    }

    public void changeRemoteDir(String remoteDir, CallbackContext callbackContext) {
        boolean changed = ftp.ChangeRemoteDir(remoteDir);
        if (changed) {
            callbackContext.success(String.valueOf(changed));
            Log.i(TAG, "Change Directory!");
        } else {
            callbackContext.error(String.valueOf(changed));
            Log.i(TAG, ftp.lastErrorText());
        }
    }

    public void deleteRemoteFile(String remoteFilename, CallbackContext callbackContext) {
        boolean delete = ftp.DeleteRemoteFile(remoteFilename);
        if (delete) {
            callbackContext.success(String.valueOf(delete));
            Log.i(TAG, "Delete File!");
        } else {
            callbackContext.error(String.valueOf(delete));
            Log.i(TAG, ftp.lastErrorText());
        }
    }

    public void getPathFromMediaUri(String url, CallbackContext callbackContext) {
        String result = null;
        Uri uri = Uri.parse(url);

        String[] projection = {MediaStore.Images.Media.DATA};
        Cursor cursor = this.cordova.getActivity().getContentResolver().query(uri, projection, null, null, null);
        int col = cursor.getColumnIndex(MediaStore.Images.Media.DATA);
        if (col >= 0 && cursor.moveToFirst())
            result = cursor.getString(col);
        cursor.close();

        if (result != null) {
            callbackContext.success(result);
            Log.i(TAG, "format File!");
        } else {
            callbackContext.error(result);
            Log.i(TAG, ftp.lastErrorText());
        }
    }


    static {
        // Important: Make sure the name passed to loadLibrary matches the shared library
        // found in your project's libs/armeabi directory.
        //  for "libchilkat.so", pass "chilkat" to loadLibrary
        //  for "libchilkatemail.so", pass "chilkatemail" to loadLibrary
        //  etc.
        //
        System.loadLibrary("chilkatftp");

        // Note: If the incorrect library name is passed to System.loadLibrary,
        // then you will see the following error message at application startup:
        //"The application <your-application-name> has stopped unexpectedly. Please try again."
    }
}
