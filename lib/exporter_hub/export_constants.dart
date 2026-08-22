// Central constants for the KrishiMithra Export Hub.
// All other files must import from here — never hard-code strings inline.

class ExportCategories {
  static const List<String> all = [
    'Coconut',
    'Fruits',
    'Vegetables',
    'Spices',
    'Cereals & Grains',
    'Pulses',
    'Oilseeds',
    'Coffee',
    'Tea',
    'Cashew',
    'Arecanut',
    'Herbs & Medicinal',
    'Flowers',
    'Organic Products',
    'Processed Agricultural Products',
    'Other',
  ];
}

class ExportUnit {
  static const String kg = 'kg';
  static const String ton = 'Ton';
  static const String quintal = 'Quintal';
  static const String mt = 'MT';
  static const String piece = 'Piece';

  static const List<String> all = ['kg', 'Ton', 'Quintal', 'MT', 'Piece'];
}

class QualityGrade {
  static const String a = 'A';
  static const String b = 'B';
  static const String c = 'C';
  static const List<String> all = ['A', 'B', 'C'];
}

class ListingStatus {
  static const String active = 'active';
  static const String inactive = 'inactive';
  static const String pendingReview = 'pending_review';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String soldOut = 'sold_out';
}

// ── Purchase Order Statuses ────────────────────────────────────────────────────
//
// Canonical status strings for the purchase_orders collection.
// Legacy aliases (po_issued, farmer_accepted, etc.) are normalised via
// POStatus.normalize() before any comparison or display.

class POStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String processing = 'processing';
  static const String readyForDispatch = 'ready_for_dispatch';
  static const String dispatched = 'dispatched';
  static const String delivered = 'delivered';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> ordered = [
    pending,
    accepted,
    processing,
    readyForDispatch,
    dispatched,
    delivered,
    completed,
  ];

  static const Set<String> terminalStatuses = {rejected, completed, cancelled};

  static const Set<String> activeStatuses = {
    pending,
    accepted,
    processing,
    readyForDispatch,
    dispatched,
    delivered,
  };

  /// Map every legacy alias to a canonical status.
  static String normalize(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'draft':
      case 'listed':
      case 'under_review':
      case 'po_issued':
        return pending;
      case 'farmer_accepted':
        return accepted;
      case 'price_negotiation':
      case 'collection_scheduled':
      case 'collected':
      case 'qc_pending':
      case 'qc_approved':
        return processing;
      case 'ready_for_export':
        return readyForDispatch;
      case 'exported':
        return completed;
      case 'qc_rejected':
        return rejected;
      default:
        return raw.toLowerCase().trim();
    }
  }

  static String displayName(String rawStatus) {
    switch (normalize(rawStatus)) {
      case pending:
        return 'Pending';
      case accepted:
        return 'Accepted';
      case rejected:
        return 'Rejected';
      case processing:
        return 'Processing';
      case readyForDispatch:
        return 'Ready for Dispatch';
      case dispatched:
        return 'Dispatched';
      case delivered:
        return 'Delivered';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return rawStatus;
    }
  }
}
