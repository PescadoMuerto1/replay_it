import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

Future<void> convertFramesToVideo(
      List<CameraImage> frames,
      double frameRate,
      Size videoDimensions,
      ) async {
    try {
      print('Converting frames to video with frame rate: $frameRate and dimensions: $videoDimensions');
      // Create a temporary directory to store the YUV420 file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_video.yuv');

      // Concatenate all YUV420 frames in memory
      final completeYUVData = <int>[];

      for (final image in frames) {
        final yPlane = image.planes[0];
        final uPlane = image.planes[1];
        final vPlane = image.planes[2];
        final width = image.width;
        final height = image.height;
        final yRowStride = yPlane.bytesPerRow;
        final uvRowStride = uPlane.bytesPerRow;
        final uvPixelStride = uPlane.bytesPerPixel ?? 1;

        // Write Y plane (Luma)
        for (int row = 0; row < height; row++) {
          completeYUVData.addAll(
              yPlane.bytes.sublist(row * yRowStride, row * yRowStride + width));
        }

        // Write UV planes (Chroma)
        for (int row = 0; row < height ~/ 2; row++) {
          for (int col = 0; col < width ~/ 2; col++) {
            int uvIndex = row * uvRowStride + col * uvPixelStride;
            completeYUVData.add(vPlane.bytes[uvIndex]); 
            completeYUVData.add(uPlane.bytes[uvIndex]); 
          }
        }
      }

      // Write the concatenated YUV data to the temporary file
      await tempFile.writeAsBytes(Uint8List.fromList(completeYUVData));


      if (tempFile.existsSync()) {
        print('The temporary file exists. ${tempFile.path}');
      } else {
        print('The temporary file does not exist.');
      }

      
      final outputPath =
          '${(await getExternalStorageDirectory())!.path}/video-${DateTime.now().microsecondsSinceEpoch}.mp4';

      final command =
          '-loglevel debug -f rawvideo -pix_fmt nv21 -s ${videoDimensions.width.toInt()}x${videoDimensions.height.toInt()} -r $frameRate -color_range 2 -i ${tempFile.path} -vf "format=yuv420p" -c:v libx264 -crf 25 $outputPath'; // Restored -crf 25

      print('frames total ${frames.length}');

      final session = await FFmpegKit.execute(command);


      // Check if the FFmpeg command was successful using getReturnCode
      final returnCode = await session.getReturnCode();
      final logs = await session.getAllLogs();

      for (final log in logs) {
        print('FFmpeg Log: ${log.getMessage()}'); // Print each log message
      }      if (ReturnCode.isSuccess(returnCode)) {
        print("FFmpegKit conversion successful");
        final result = await ImageGallerySaverPlus.saveFile(outputPath);
        print('Video saved to gallery: $result');
        if (result['isSuccess']) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text('Video saved to gallery!')),
          // );
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Error saving video: ${result['errorMessage']}')),
          // );
        }
      } else {
        print("FFmpegKit conversion failed with return code: $returnCode");
      }
      print(
          'kit logs: ${returnCode != null ? returnCode.isValueSuccess() : 'no rv'}');

      // Delete the temporary file after processing
      await tempFile.delete();
    } catch (e) {
      print('Error: $e');
    }
  }

// Hybrid chunk-based conversion function
Future<String?> convertChunksToVideo(List<String> chunkFiles, double frameRate, Size dimensions) async {
  print('Converting ${chunkFiles.length} chunk files to video with frame rate: $frameRate and dimensions: $dimensions');
  
  try {
    // Create a snapshot of the chunk files to avoid concurrent modification
    final chunkFilesCopy = List<String>.from(chunkFiles);
    print('DEBUG: Created snapshot of ${chunkFilesCopy.length} chunk files');
    
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final concatenatedFilePath = '${directory.path}/concatenated_$timestamp.yuv';
    final outputVideoPath = '${directory.path}/output_$timestamp.mp4';

    print('DEBUG: Creating concatenated file at: $concatenatedFilePath');
    print('DEBUG: Output video path: $outputVideoPath');

    // Concatenate all chunk files into one YUV file
    final concatenatedFile = File(concatenatedFilePath);
    final sink = concatenatedFile.openWrite();

    print('DEBUG: Starting chunk concatenation...');
    for (final chunkPath in chunkFilesCopy) {
      final chunkFile = File(chunkPath);
      if (await chunkFile.exists()) {
        print('DEBUG: Reading chunk file: $chunkPath');
        final chunkData = await chunkFile.readAsBytes();
        sink.add(chunkData);
        print('DEBUG: Added ${chunkData.length} bytes from chunk');
      } else {
        print('DEBUG: WARNING - Chunk file does not exist: $chunkPath');
      }
    }

    await sink.close();
    print('DEBUG: Finished concatenating chunks. File size: ${await concatenatedFile.length()} bytes');

    // Verify concatenated file exists
    if (!await concatenatedFile.exists()) {
      print('ERROR: Concatenated file was not created');
      return null;
    }

    // Build FFmpeg command
    final command =
        '-loglevel debug -f rawvideo -pix_fmt nv21 -s ${dimensions.width.toInt()}x${dimensions.height.toInt()} -r $frameRate -color_range 2 -i $concatenatedFilePath -vf "format=yuv420p" -c:v libx264 -crf 18 $outputVideoPath';

    print('DEBUG: Executing FFmpeg command');
    final session = await FFmpegKit.execute(command);

    // Check FFmpeg result
    final returnCode = await session.getReturnCode();
    final logs = await session.getAllLogs();

    print('DEBUG: FFmpeg logs:');
    for (final log in logs) {
      print('FFmpeg: ${log.getMessage()}');
    }

    if (ReturnCode.isSuccess(returnCode)) {
      print("DEBUG: FFmpeg conversion successful");
      
      // Save to gallery
      print('DEBUG: Saving video to gallery...');
      final result = await ImageGallerySaverPlus.saveFile(outputVideoPath);
      print('DEBUG: Gallery save result: $result');
      
      // Clean up temporary files
      await concatenatedFile.delete();
      await File(outputVideoPath).delete();
      
      return outputVideoPath;
    } else {
      print("ERROR: FFmpeg conversion failed with return code: $returnCode");
      await concatenatedFile.delete();
      return null;
    }
  } catch (e, stackTrace) {
    print('ERROR in convertChunksToVideo: $e');
    print('Stack trace: $stackTrace');
    return null;
  }
}