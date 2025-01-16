// lib/screens/digital_profile/tabs/header/header_tab.dart
// Profile header editing interface, Manages profile/company images and banner, Handles profile information form and social links
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/digital_profile_provider.dart';
import '../../../../widgets/digital_profile/banner_upload.dart';
import '../../../../widgets/digital_profile/company_image_upload.dart';
import '../../../../widgets/digital_profile/profile_form.dart';
import '../../../../widgets/digital_profile/profile_image_upload.dart';
import '../../../../widgets/digital_profile/social_icons.dart';

class HeaderTab extends StatefulWidget {
 const HeaderTab({super.key});

 @override
 State<HeaderTab> createState() => _HeaderTabState();
}

class _HeaderTabState extends State<HeaderTab> {
 @override
 Widget build(BuildContext context) {
   return Consumer<DigitalProfileProvider>(
     builder: (context, provider, child) {
       if (provider.profileData.id.isEmpty) {
         return const Center(child: CircularProgressIndicator());
       }

       final currentLayout = provider.profileData.layout;

       return GestureDetector(
         onTap: () => FocusScope.of(context).unfocus(),
         child: SingleChildScrollView(
           padding: const EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               const SizedBox(height: 8),
               Row(
                 children: [
                   Expanded(
                     child: ProfileImageUpload(
                       currentImageUrl: provider.profileData.profileImageUrl,
                       onImageUploaded: (url) {
                         provider.updateProfile(profileImageUrl: url);
                       },
                     ),
                   ),
                   if (currentLayout != ProfileLayout.portrait) ...[
                     const SizedBox(width: 16),
                     Expanded(
                       child: CompanyImageUpload(
                         currentImageUrl: provider.profileData.companyImageUrl,
                         onImageUploaded: (url) {
                           provider.updateProfile(companyImageUrl: url);
                         },
                       ),
                     ),
                   ],
                 ],
               ),
               if (currentLayout == ProfileLayout.banner) ...[
                 const SizedBox(height: 24),
                 BannerUpload(
                   currentImageUrl: provider.profileData.bannerImageUrl,
                   onImageUploaded: (url) {
                     provider.updateProfile(bannerImageUrl: url);
                   },
                 ),
               ],
               const SizedBox(height: 24),
               const ProfileForm(),
               const SizedBox(height: 24),
               const SocialIcons(),
               const SizedBox(height: 50),
             ],
           ),
         ),
       );
     },
   );
 }
}