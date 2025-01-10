// lib/models/social_platform.dart
// Social media platform configurations, URL validation and formatting, Platform-specific icon management
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum UrlHandlingType {
  preserveAll,    // Keep entire URL including UTM
  preserveFrontOnly,    // Keep protocol/www but remove UTM
  usernameOnly,    // Convert to standard URL format
  urlOnly    // Preserve front, remove UTM
}

class SocialPlatform {
  final String id;
  final String name;
  final IconData? icon;
  final String? imagePath;
  final String? placeholder;
  final String? prefix;
  final String? value;
  final RegExp? validationPattern;
  final bool requiresCountryCode;
  final bool numbersOnly;
  final String? urlPattern;
  final UrlHandlingType urlHandlingType;
  final String? standardUrlFormat;    // For username-only platforms
  final int? sequence;

  const SocialPlatform({
    required this.id,
    required this.name,
    this.icon,
    this.imagePath,
    this.placeholder,
    this.prefix,
    this.value,
    this.validationPattern,
    this.requiresCountryCode = false,
    this.numbersOnly = false,
    this.urlPattern,
    this.urlHandlingType = UrlHandlingType.preserveFrontOnly,
    this.standardUrlFormat,
    this.sequence,
  }) : assert(icon != null || imagePath != null,
            'Either icon or imagePath must be provided');

  String? parseUrl(String input) {
    if (input.isEmpty) return input;

    switch (urlHandlingType) {
      case UrlHandlingType.urlOnly:
        if (id == 'website') {
          return input.split('?')[0];    // Only remove UTM tracking
        }
        if (id == 'googlePlay') {
          // Remove https:// and www. but keep UTM parameters
          return input.replaceAll(RegExp(r'^(https?:\/\/)?(www\.)?'), '');
        }
        String result = input.replaceAll(RegExp(r'^(https?:\/\/)?(www\.)?'), '');
        return result.split('?')[0];

      case UrlHandlingType.preserveFrontOnly:
        // Handle Line, Weibo, and Naver similar to Google Play
        if (id == 'line' || id == 'weibo' || id == 'naver') {
          return input.replaceAll(RegExp(r'^(https?:\/\/)?(www\.)?'), '');
        }
        // Other platforms like Facebook, LinkedIn etc.
        return input.contains('?') ? input.split('?')[0] : input;

      case UrlHandlingType.usernameOnly:
        String username = input;
        if (input.contains('/')) {
          username = input.split('/').last;
        }
        username = username.replaceAll('@', '');
        return username;
        
      case UrlHandlingType.preserveAll:
        return input;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'urlHandlingType': urlHandlingType.toString(),
      'standardUrlFormat': standardUrlFormat,
    };
  }

  static SocialPlatform fromMap(Map<String, dynamic> map) {
    final platform = SocialPlatforms.platforms.firstWhere(
      (p) => p.id == map['id'],
      orElse: () => SocialPlatform(
        id: map['id'],
        name: map['name'],
        icon: FontAwesomeIcons.link,
      ),
    );

    return platform.copyWith(
      value: map['value'],
      sequence: map['sequence'],
    );
  }

  SocialPlatform copyWith({String? value, int? sequence}) {
    return SocialPlatform(
      id: id,
      name: name,
      icon: icon,
      imagePath: imagePath,
      placeholder: placeholder,
      prefix: prefix,
      value: value ?? this.value,
      validationPattern: validationPattern,
      requiresCountryCode: requiresCountryCode,
      numbersOnly: numbersOnly,
      urlPattern: urlPattern,
      urlHandlingType: urlHandlingType,
      standardUrlFormat: standardUrlFormat,
      sequence: sequence ?? this.sequence,
    );
  }
}

class SocialPlatforms {
  static final List<SocialPlatform> platforms = [
    // General
    SocialPlatform(
      id: 'website',
      name: 'Website',
      icon: FontAwesomeIcons.globe,
      placeholder: 'Enter website URL',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),
    SocialPlatform(
      id: 'address',
      name: 'Address',
      icon: FontAwesomeIcons.locationDot,
      placeholder: 'Enter business address',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),

    // Social Media with username format
    SocialPlatform(
      id: 'tumblr',
      name: 'Tumblr',
      icon: FontAwesomeIcons.tumblr,
      placeholder: 'Enter username',
      prefix: '@',
      standardUrlFormat: 'https://www.tumblr.com/{username}',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'mastodon',
      name: 'Mastodon',
      icon: FontAwesomeIcons.mastodon,
      placeholder: 'Enter username',
      prefix: '@',
      standardUrlFormat: 'https://mastodon.social/@{username}',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'pinterest',
      name: 'Pinterest',
      icon: FontAwesomeIcons.pinterest,
      placeholder: 'Enter username',
      prefix: '@',
      standardUrlFormat: 'https://www.pinterest.com/{username}',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'github',
      name: 'GitHub',
      icon: FontAwesomeIcons.github,
      placeholder: 'Enter username',
      prefix: '@',
      standardUrlFormat: 'https://github.com/{username}',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'gitlab',
      name: 'GitLab',
      icon: FontAwesomeIcons.gitlab,
      placeholder: 'Enter username',
      prefix: '@',
      standardUrlFormat: 'https://gitlab.com/{username}',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'youtube',
      name: 'YouTube',
      icon: FontAwesomeIcons.youtube,
      placeholder: 'Enter username',
      prefix: '@',
      standardUrlFormat: 'https://www.youtube.com/@{username}',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'twitch',
      name: 'Twitch',
      icon: FontAwesomeIcons.twitch,
      placeholder: 'Enter username',
      prefix: '@',
      standardUrlFormat: 'https://www.twitch.tv/{username}',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'reddit',
      name: 'Reddit',
      icon: FontAwesomeIcons.reddit,
      placeholder: 'Enter username',
      prefix: '@',
      standardUrlFormat: 'https://www.reddit.com/user/{username}',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'steam',
      name: 'Steam',
      icon: FontAwesomeIcons.steam,
      placeholder: 'Enter username',
      prefix: '@',
      standardUrlFormat: 'https://steamcommunity.com/id/{username}',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'etsy',
      name: 'Etsy',
      icon: FontAwesomeIcons.etsy,
      placeholder: 'Enter username',
      prefix: '@',
      standardUrlFormat: 'https://www.etsy.com/shop/{username}',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'dribbble',
      name: 'Dribbble',
      icon: FontAwesomeIcons.dribbble,
      placeholder: 'Enter username',
      prefix: '@',
      standardUrlFormat: 'https://dribbble.com/{username}',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'behance',
      name: 'Behance',
      icon: FontAwesomeIcons.behance,
      placeholder: 'Enter username',
      prefix: '@',
      standardUrlFormat: 'https://www.behance.net/{username}',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),

    // URL-only platforms
    SocialPlatform(
      id: 'line',
      name: 'Line',
      icon: FontAwesomeIcons.line,
      placeholder: 'Enter Line URL or username',
      urlPattern: r'^(?:https?:\/\/)?(?:www\.)?line\.me\/ti\/p\/[\w\.\-]+\/?$',
      urlHandlingType: UrlHandlingType.preserveFrontOnly,
    ),
    SocialPlatform(
      id: 'weibo',
      name: 'Weibo',
      icon: FontAwesomeIcons.weibo,
      placeholder: 'Enter Weibo URL',
      urlPattern: r'^(?:https?:\/\/)?(?:www\.)?weibo\.com\/u\/[\w\.\-]+\/?$',
      urlHandlingType: UrlHandlingType.preserveFrontOnly,
    ),
    SocialPlatform(
      id: 'naver',
      name: 'Naver',
      imagePath: 'assets/social_icons/naver.svg',
      placeholder: 'Enter Naver URL',
      urlPattern: r'^(?:https?:\/\/)?(?:www\.)?blog\.naver\.com\/[\w\.\-]+\/?$',
      urlHandlingType: UrlHandlingType.preserveFrontOnly,
    ),
    SocialPlatform(
      id: 'bluesky',
      name: 'Bluesky',
      icon: FontAwesomeIcons.bluesky,
      placeholder: 'Enter Bluesky URL',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),
    SocialPlatform(
      id: 'discord',
      name: 'Discord',
      icon: FontAwesomeIcons.discord,
      placeholder: 'Enter Discord URL',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),
    SocialPlatform(
      id: 'googleReviews',
      name: 'Google Reviews',
      icon: FontAwesomeIcons.google,
      placeholder: 'Enter Google Maps URL',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),
    SocialPlatform(
      id: 'shopee',
      name: 'Shopee',
      imagePath: 'assets/social_icons/shopee.svg',
      placeholder: 'Enter Shopee URL',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),
    SocialPlatform(
      id: 'lazada',
      name: 'Lazada',
      imagePath: 'assets/social_icons/lazada.svg',
      placeholder: 'Enter Lazada URL',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),
    SocialPlatform(
      id: 'amazon',
      name: 'Amazon',
      icon: FontAwesomeIcons.amazon,
      placeholder: 'Enter Amazon URL',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),
    SocialPlatform(
      id: 'phone',
      name: 'Phone',
      icon: FontAwesomeIcons.phone,
      placeholder: 'Enter phone number',
      validationPattern: RegExp(r'^\d{1,15}$'),
      requiresCountryCode: true,
      numbersOnly: true,
    ),
    SocialPlatform(
      id: 'sms',
      name: 'SMS',
      icon: FontAwesomeIcons.commentSms,
      placeholder: 'Enter phone number',
      validationPattern: RegExp(r'^\d{1,15}$'),
      requiresCountryCode: true,
      numbersOnly: true,
    ),
    SocialPlatform(
      id: 'email',
      name: 'Email',
      icon: FontAwesomeIcons.envelope,
      placeholder: 'Enter email address',
      validationPattern: RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'),
    ),
    SocialPlatform(
      id: 'facebook',
      name: 'Facebook',
      icon: FontAwesomeIcons.facebook,
      placeholder: 'facebook.com/',
      urlPattern: r'^(?:https?:\/\/)?(?:www\.)?facebook\.com\/[\w\.\-]+\/?$',
      urlHandlingType: UrlHandlingType.preserveFrontOnly,
    ),
    SocialPlatform(
      id: 'instagram',
      name: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      placeholder: 'Enter username or paste URL',
      prefix: '@',
      urlPattern: r'^(?:https?:\/\/)?(?:www\.)?instagram\.com\/[\w\.\-]+\/?$',
      urlHandlingType: UrlHandlingType.usernameOnly,
      standardUrlFormat: 'https://instagram.com/{username}',
    ),
    SocialPlatform(
      id: 'linkedin',
      name: 'LinkedIn',
      icon: FontAwesomeIcons.linkedin,
      placeholder: 'linkedin.com/in/',
      urlPattern: r'^(?:https?:\/\/)?(?:www\.)?linkedin\.com\/(?:in|company)\/[\w\-\.]+\/?$',
      urlHandlingType: UrlHandlingType.preserveFrontOnly,
    ),
    SocialPlatform(
      id: 'tiktok',
      name: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      placeholder: 'Enter username or paste URL',
      prefix: '@',
      urlPattern: r'^(?:https?:\/\/)?(?:www\.)?tiktok\.com\/@[\w\.\-]+\/?$',
      urlHandlingType: UrlHandlingType.usernameOnly,
      standardUrlFormat: 'https://tiktok.com/@{username}',
    ),
    SocialPlatform(
      id: 'twitter',
      name: 'X (Twitter)',
      icon: FontAwesomeIcons.xTwitter,
      placeholder: 'Enter username or paste URL',
      prefix: '@',
      urlPattern: r'^(?:https?:\/\/)?(?:www\.)?twitter\.com\/[\w\.\-]+\/?$',
      urlHandlingType: UrlHandlingType.usernameOnly,
      standardUrlFormat: 'https://twitter.com/{username}',
    ),
    SocialPlatform(
      id: 'threads',
      name: 'Threads',
      icon: FontAwesomeIcons.threads,
      placeholder: 'Enter username or paste URL',
      prefix: '@',
      urlPattern: r'^(?:https?:\/\/)?(?:www\.)?threads\.net\/@[\w\.\-]+\/?$',
      urlHandlingType: UrlHandlingType.usernameOnly,
      standardUrlFormat: 'https://threads.net/@{username}',
    ),
    SocialPlatform(
      id: 'linkedin_company',
      name: 'LinkedIn Company',
      icon: FontAwesomeIcons.linkedin,
      placeholder: 'linkedin.com/company/',
      urlPattern: r'^(?:https?:\/\/)?(?:www\.)?linkedin\.com\/company\/[\w\-\.]+\/?$',
      urlHandlingType: UrlHandlingType.preserveFrontOnly,
    ),
    SocialPlatform(
      id: 'snapchat',
      name: 'Snapchat',
      icon: FontAwesomeIcons.snapchat,
      placeholder: 'Enter username',
      prefix: '@',
      urlHandlingType: UrlHandlingType.usernameOnly,
      standardUrlFormat: 'https://snapchat.com/add/{username}',
    ),
    // App Stores & Dev
    SocialPlatform(
      id: 'googlePlay',
      name: 'Google Play',
      icon: FontAwesomeIcons.googlePlay,
      placeholder: 'Enter app URL',
      urlPattern: r'^(?:https?:\/\/)?(?:play\.)?google\.com\/store\/apps\/details\?id=[\w\.\-]+\/?$',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),
    SocialPlatform(
      id: 'appStore',
      name: 'App Store',
      icon: FontAwesomeIcons.appStore,
      placeholder: 'Enter app URL',
      urlPattern: r'^(?:https?:\/\/)?(?:apps\.)?apple\.com\/[\w\.\-\/]+\/?$',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),
    // Messaging
    SocialPlatform(
      id: 'whatsapp',
      name: 'WhatsApp',
      icon: FontAwesomeIcons.whatsapp,
      placeholder: 'Enter phone number',
      validationPattern: RegExp(r'^\d{1,15}$'),
      requiresCountryCode: true,
      numbersOnly: true,
    ),
    SocialPlatform(
      id: 'telegram',
      name: 'Telegram',
      icon: FontAwesomeIcons.telegram,
      placeholder: 'Enter username',
      prefix: '@',
      urlPattern: r'^(?:https?:\/\/)?(?:www\.)?t\.me\/[\w\.\-]+\/?$',
      urlHandlingType: UrlHandlingType.usernameOnly,
      standardUrlFormat: 'https://t.me/{username}',
    ),
    SocialPlatform(
      id: 'wechat',
      name: 'WeChat',
      icon: FontAwesomeIcons.weixin,
      placeholder: 'Enter WeChat ID',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'kakaotalk',
      name: 'KakaoTalk',
      imagePath: 'assets/social_icons/kakaotalk.svg',
      placeholder: 'Enter KakaoTalk ID',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'zalo',
      name: 'Zalo',
      imagePath: 'assets/social_icons/zalo.svg',
      placeholder: 'Enter Zalo phone number',
      validationPattern: RegExp(r'^\d{1,15}$'),
      requiresCountryCode: true,
      numbersOnly: true,
    ),
    SocialPlatform(
      id: 'red',
      name: 'RED 小红书',
      imagePath: 'assets/social_icons/red.svg',
      placeholder: 'Enter RED URL',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),
    SocialPlatform(
      id: 'lemon8',
      name: 'Lemon8',
      imagePath: 'assets/social_icons/lemon8.svg',
      placeholder: 'Enter Lemon8 URL',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),
    SocialPlatform(
      id: 'douyin',
      name: '抖音',
      icon: FontAwesomeIcons.tiktok,
      placeholder: 'Enter Douyin URL',
      urlHandlingType: UrlHandlingType.urlOnly,
    ),
    SocialPlatform(
      id: 'qq',
      name: 'QQ',
      icon: FontAwesomeIcons.qq,
      placeholder: 'Enter QQ ID',
      urlHandlingType: UrlHandlingType.usernameOnly,
    ),
    SocialPlatform(
      id: 'viber',
      name: 'Viber',
      icon: FontAwesomeIcons.viber,
      placeholder: 'Enter phone number',
      validationPattern: RegExp(r'^\d{1,15}$'),
      requiresCountryCode: true,
      numbersOnly: true,
    ),
  ];
}