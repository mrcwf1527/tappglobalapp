// lib/widgets/digital_profile/banner_upload.dart
import 'package:flutter/material.dart';

class BannerUpload extends StatelessWidget {
 const BannerUpload({super.key});

 @override
 Widget build(BuildContext context) {
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       const Text('Banner Image',
           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
       const SizedBox(height: 8),
       AspectRatio(
         aspectRatio: 2.6,
         child: Container(
           decoration: BoxDecoration(
             color: Theme.of(context).brightness == Brightness.dark
                 ? Colors.grey[900]
                 : Colors.grey[200],
             borderRadius: BorderRadius.circular(8),
           ),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.image_outlined, size: 24),
               const SizedBox(height: 4),
               Text(
                 'Select file or drag and drop',
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   fontSize: 12,
                   color: Theme.of(context).brightness == Brightness.dark
                       ? Colors.grey[400]
                       : Colors.grey[600],
                 ),
               ),
             ],
           ),
         ),
       ),
     ],
   );
 }
}