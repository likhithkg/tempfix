import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'labour_model.dart';
import 'labour_hub_form_page.dart';
import 'hire_request_form_page.dart';

import '../services/libre_translate_service.dart';
import '../l10n/app_localizations.dart';

class LabourHubDetailPage extends StatefulWidget {
  final Labour labour;

  const LabourHubDetailPage({
    super.key,
    required this.labour,
  });

  @override
  State<LabourHubDetailPage> createState() =>
      _LabourHubDetailPageState();
}

class _LabourHubDetailPageState
    extends State<LabourHubDetailPage> {

  String translatedName = '';

  String translatedSkill = '';

  String translatedLocation = '';

  String translatedAvailability = '';

  String translatedTitle = '';

  String translatedCall = '';

  String translatedHire = '';

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _translateAll();
  }

  Future<void> _translateAll() async {

    final lang =
        Localizations.localeOf(context)
            .languageCode;

    if (lang == 'en') {

      setState(() {

        translatedName =
            widget.labour.name;

        translatedSkill =
            widget.labour.skill;

        translatedLocation =
            widget.labour.location;

        final l = AppLocalizations.of(context)!;
        translatedAvailability =
            widget.labour.available

                ? l.available

                : l.notAvailable;

        translatedTitle = '';
        translatedCall = '';
        translatedHire = '';

        loading = false;
      });

      return;
    }

    translatedName =
        await LibreTranslateService
            .translateText(
      text: widget.labour.name,
      targetLanguage: lang,
    );

    translatedSkill =
        await LibreTranslateService
            .translateText(
      text: widget.labour.skill,
      targetLanguage: lang,
    );

    translatedLocation =
        await LibreTranslateService
            .translateText(
      text: widget.labour.location,
      targetLanguage: lang,
    );

    translatedAvailability =
        await LibreTranslateService
            .translateText(
      text: widget.labour.available
          ? "Available"
          : "Not Available",
      targetLanguage: lang,
    );  // LibreTranslate used for user-data translation; English source is intentional

    if (mounted) {

      setState(() {

        loading = false;
      });
    }
  }

  Future<void> _callNumber(
    String number,
  ) async {

    final Uri uri = Uri(
      scheme: 'tel',
      path: number,
    );

    if (await canLaunchUrl(uri)) {

      await launchUrl(uri);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {

    final labour = widget.labour;
    final l = AppLocalizations.of(context)!;

    final String? currentUserId =
        FirebaseAuth
            .instance
            .currentUser
            ?.uid;

    return Scaffold(

      backgroundColor:
          Colors.grey.shade100,

      appBar: AppBar(

        title: Text(

          loading
              ? l.loading
              : l.labourDetails,
        ),

        backgroundColor:
            Colors.green.shade700,

        elevation: 2,

        actions: [

          if (labour.createdBy ==
              currentUserId)

            PopupMenuButton<String>(

              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
              ),

              onSelected: (value) {

                if (value == 'edit') {

                  Navigator.push(

                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                          LabourHubFormPage(
                        labour: labour,
                      ),
                    ),
                  );

                } else if (
                    value ==
                        'delete') {

                  ScaffoldMessenger.of(
                          context)
                      .showSnackBar(

                    SnackBar(

                      content: Text(
                        l.deleteOptionAvailableInListingPage,
                      ),
                    ),
                  );
                }
              },

              itemBuilder:
                  (context) => [

                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    l.editLabour,
                  ),
                ),

                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    l.deleteLabour,
                  ),
                ),
              ],
            ),
        ],
      ),

      body: loading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : SingleChildScrollView(

              padding:
                  const EdgeInsets.all(
                16,
              ),

              child: Column(

                children: [

                  // MAIN CARD
                  Container(

                    padding:
                        const EdgeInsets
                            .all(20),

                    decoration:
                        BoxDecoration(

                      color:
                          Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),

                      boxShadow: [

                        BoxShadow(

                          color: Colors
                              .black
                              .withValues(alpha:
                            0.06,
                          ),

                          blurRadius: 8,

                          offset:
                              const Offset(
                            0,
                            3,
                          ),
                        ),
                      ],
                    ),

                    child: Column(

                      children: [

                        CircleAvatar(

                          radius: 40,

                          backgroundColor:
                              labour.available

                                  ? Colors
                                      .green
                                      .shade100

                                  : Colors
                                      .red
                                      .shade100,

                          backgroundImage:
                              labour.imageUrl !=
                                          null &&
                                      labour.imageUrl!
                                          .isNotEmpty

                                  ? NetworkImage(
                                      labour.imageUrl!,
                                    )

                                  : const AssetImage(
                                          'assets/farmer_logo.png',
                                        )
                                      as ImageProvider,

                          onBackgroundImageError:
                              (_, __) {},

                          child: null,
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        Text(

                          translatedName,

                          style:
                              const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        if (translatedSkill
                            .trim()
                            .isNotEmpty)

                          Column(
                            children: [
                              Text(
                                l.skillProfessionLabel,
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                translatedSkill,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(
                          height: 10,
                        ),

                        Chip(

                          label: Text(

                            translatedAvailability,

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                            ),
                          ),

                          backgroundColor:
                              labour.available

                                  ? Colors.green

                                  : Colors.red,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // DETAILS CARD
                  Container(

                    padding:
                        const EdgeInsets
                            .all(20),

                    decoration:
                        BoxDecoration(

                      color:
                          Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),

                      boxShadow: [

                        BoxShadow(

                          color: Colors
                              .black
                              .withValues(alpha:
                            0.06,
                          ),

                          blurRadius: 8,

                          offset:
                              const Offset(
                            0,
                            3,
                          ),
                        ),
                      ],
                    ),

                    child: Column(

                      children: [

                        // LOCATION
                        Row(

                          children: [

                            const Icon(
                              Icons.location_on,
                              color:
                                  Colors.green,
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.locationLabel, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  Text(translatedLocation, style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Divider(
                          height: 28,
                        ),

                        // CONTACT
                        Row(

                          children: [

                            const Icon(
                              Icons.phone,
                              color:
                                  Colors.green,
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.mobileLabel, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  Text(labour.contact, style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                            ),

                            IconButton(

                              icon: const Icon(
                                Icons.call,
                                color:
                                    Colors.green,
                              ),

                              onPressed: () =>
                                  _callNumber(
                                labour.contact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // CALL BUTTON
                  SizedBox(

                    width: double.infinity,

                    child:
                        ElevatedButton.icon(

                      icon: const Icon(
                        Icons.call,
                      ),

                      label: Text(

                        l.callLabour,

                        style:
                            const TextStyle(
                          fontSize: 18,
                        ),
                      ),

                      style:
                          ElevatedButton.styleFrom(

                        backgroundColor:
                            Colors.green
                                .shade700,

                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),

                        shape:
                            RoundedRectangleBorder(

                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),

                      onPressed: () =>
                          _callNumber(
                        labour.contact,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // HIRE BUTTON
                  SizedBox(

                    width: double.infinity,

                    child:
                        ElevatedButton.icon(

                      icon: const Icon(
                        Icons.work,
                      ),

                      label: Text(

                        l.hireLabour,

                        style:
                            const TextStyle(
                          fontSize: 18,
                        ),
                      ),

                      style:
                          ElevatedButton.styleFrom(

                        backgroundColor:
                            Colors.orange
                                .shade700,

                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),

                        shape:
                            RoundedRectangleBorder(

                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),

                      onPressed: () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) =>
                                HireRequestFormPage(

                              labourId:
                                  labour.id,

                              labourName:
                                  labour.name,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}