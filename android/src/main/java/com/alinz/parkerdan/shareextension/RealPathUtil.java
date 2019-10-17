package com.alinz.parkerdan.shareextension;

import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.content.ContentUris;
import android.os.Environment;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.UUID;

public class RealPathUtil {
    public static String getRealPathFromURI(final Context context, final Uri uri, String fileExtension) {

        final boolean isKitKat = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;

        // DocumentProvider
        if (isKitKat && DocumentsContract.isDocumentUri(context, uri)) {
            // ExternalStorageProvider
            if (isExternalStorageDocument(uri)) {
                final String docId = DocumentsContract.getDocumentId(uri);
                final String[] split = docId.split(":");
                final String type = split[0];

                if ("primary".equalsIgnoreCase(type)) {
                    return Environment.getExternalStorageDirectory() + "/" + split[1];
                }

                // TODO handle non-primary volumes
            }
            // DownloadsProvider
            else if (isDownloadsDocument(uri)) {

                final String id = DocumentsContract.getDocumentId(uri);
                final Uri contentUri = ContentUris.withAppendedId(
                        Uri.parse("content://downloads/public_downloads"), Long.valueOf(id));

                return getDataColumn(context, contentUri, null, null);
            }
            // MediaProvider
            else if (isMediaDocument(uri)) {
                final String docId = DocumentsContract.getDocumentId(uri);
                final String[] split = docId.split(":");
                final String type = split[0];

                Uri contentUri = null;
                if ("image".equals(type)) {
                    contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
                } else if ("video".equals(type)) {
                    contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
                } else if ("audio".equals(type)) {
                    contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
                }

                final String selection = "_id=?";
                final String[] selectionArgs = new String[]{
                        split[1]
                };

                return getDataColumn(context, contentUri, selection, selectionArgs);
            }
        }
        // MediaStore (and general)
        else if ("content".equalsIgnoreCase(uri.getScheme())) {
            return getImagePath(context, uri, fileExtension);
        }
        // File
        else if ("file".equalsIgnoreCase(uri.getScheme())) {
            return uri.getPath();
        }

        return null;
    }

    /**
     * Get the value of the data column for this Uri. This is useful for
     * MediaStore Uris, and other file-based ContentProviders.
     *
     * @param context       The context.
     * @param uri           The Uri to query.
     * @param selection     (Optional) Filter used in the query.
     * @param selectionArgs (Optional) Selection arguments used in the query.
     * @return The value of the _data column, which is typically a file path.
     */
    public static String getDataColumn(Context context, Uri uri, String selection,
                                       String[] selectionArgs) {

        Cursor cursor = null;
        final String column = "_data";
        final String[] projection = {
                column
        };

        try {
            cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs,
                    null);
            if (cursor != null && cursor.moveToFirst()) {
                final int index = cursor.getColumnIndexOrThrow(column);
                return cursor.getString(index);
            }
        } finally {
            if (cursor != null)
                cursor.close();
        }
        return null;
    }


    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is ExternalStorageProvider.
     */
    public static boolean isExternalStorageDocument(Uri uri) {
        return "com.android.externalstorage.documents".equals(uri.getAuthority());
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is DownloadsProvider.
     */
    public static boolean isDownloadsDocument(Uri uri) {
        return "com.android.providers.downloads.documents".equals(uri.getAuthority());
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is MediaProvider.
     */
    public static boolean isMediaDocument(Uri uri) {
        return "com.android.providers.media.documents".equals(uri.getAuthority());
    }

    public static String getImagePath(Context context, Uri uri, String fileExtension) {
        if ("content".equalsIgnoreCase(uri.getScheme())) {

            if (isGoogleOldPhotosUri(uri)) {
                // return http path, then download file.
                return uri.getLastPathSegment();
            } else if (isGoogleNewPhotosUri(uri) || isMMSFile(uri)) {
                // copy from uri. context.getContentResolver().openInputStream(uri);
                return copyFile(context, uri, fileExtension);
            }
        }

        String dataFromUri = getDataColumn(context, uri, null, null);

        if (dataFromUri == null) {
            return copyFile(context, uri, fileExtension);
        }

        String[] arrOfStrings = dataFromUri.split("content://");

        if (arrOfStrings.length > 1) {
            return copyFile(context, uri, fileExtension);
        }

        return dataFromUri;
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is Google Photos.
     */
    public static boolean isGoogleOldPhotosUri(Uri uri) {
        return "com.google.android.apps.photos.content".equals(uri.getAuthority());
    }

    public static boolean isGoogleNewPhotosUri(Uri uri) {
        return "com.google.android.apps.photos.contentprovider".equals(uri.getAuthority());
    }

    public static boolean isMMSFile(Uri uri) {
        return "com.android.mms.file".equals(uri.getAuthority());
    }

    private static String copyFile(Context context, Uri uri, String fileExtension) {

        String extension;

        switch (fileExtension) {
            case "image/jpeg":
                extension = ".jpg";
                break;
            case "image/png":
                extension = ".png";
                break;
            case "application/pdf":
                extension = ".pdf";
                break;
            default:
                extension = ".jpg";
        }

        String filePath;
        InputStream inputStream = null;
        BufferedOutputStream outStream = null;
        try {
            inputStream = context.getContentResolver().openInputStream(uri);

            File extDir = context.getExternalFilesDir(null);

            filePath = extDir.getAbsolutePath() + "/IMG_" + UUID.randomUUID().toString() + extension;

            outStream = new BufferedOutputStream(new FileOutputStream
                    (filePath));

            byte[] buf = new byte[2048];
            int len;
            while ((len = inputStream.read(buf)) > 0) {
                outStream.write(buf, 0, len);
            }

        } catch (IOException e) {
            e.printStackTrace();
            filePath = "";
        } finally {
            try {
                if (inputStream != null) {
                    inputStream.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
            try {
                if (outStream != null) {
                    outStream.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        return filePath;
    }

}
