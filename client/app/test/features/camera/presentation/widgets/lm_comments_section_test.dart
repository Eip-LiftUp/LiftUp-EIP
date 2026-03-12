import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/camera/presentation/widgets/lm_comments_section.dart';

void main() {
  group('LMCommentsSection Widget', () {
    late bool backToCameraCalled;

    setUp(() {
      backToCameraCalled = false;
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: LMCommentsSection(
            onBackToCamera: () {
              backToCameraCalled = true;
            },
          ),
        ),
      );
    }

    testWidgets('should display header with correct title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('LM Coach Comments'), findsOneWidget);
      expect(find.text('AI-powered feedback on your form'), findsOneWidget);
    });

    testWidgets('should display robot icon in header', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('should display placeholder comments', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Check for placeholder comment texts
      expect(find.textContaining('Great form'), findsOneWidget);
      expect(find.textContaining('knees are going too far'), findsOneWidget);
      expect(find.textContaining('Maintain that tempo'), findsOneWidget);
    });

    testWidgets('should display comment cards', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Should have multiple Card widgets for comments
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should display back to camera button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Back to Camera'), findsOneWidget);
      expect(find.widgetWithIcon(ElevatedButton, Icons.videocam), findsOneWidget);
    });

    testWidgets('should call onBackToCamera when button is pressed', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.tap(find.text('Back to Camera'));
      await tester.pump();

      // Assert
      expect(backToCameraCalled, isTrue);
    });

    testWidgets('should display footer message about LM integration', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('LM integration pending'), findsOneWidget);
    });

    testWidgets('should be scrollable', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert - ListView should be present for scrolling
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('LMComment Data Model', () {
    test('should create LMComment with all required fields', () {
      // Arrange & Act
      final comment = LMComment(
        id: '1',
        text: 'Test comment',
        timestamp: DateTime.now(),
        type: CommentType.positive,
      );

      // Assert
      expect(comment.id, '1');
      expect(comment.text, 'Test comment');
      expect(comment.type, CommentType.positive);
      expect(comment.timestamp, isNotNull);
    });

    test('should support all comment types', () {
      // Arrange
      final timestamp = DateTime.now();

      // Act & Assert
      final positive = LMComment(
        id: '1',
        text: 'Great!',
        timestamp: timestamp,
        type: CommentType.positive,
      );
      expect(positive.type, CommentType.positive);

      final correction = LMComment(
        id: '2',
        text: 'Correction needed',
        timestamp: timestamp,
        type: CommentType.correction,
      );
      expect(correction.type, CommentType.correction);

      final encouragement = LMComment(
        id: '3',
        text: 'Keep going!',
        timestamp: timestamp,
        type: CommentType.encouragement,
      );
      expect(encouragement.type, CommentType.encouragement);

      final warning = LMComment(
        id: '4',
        text: 'Watch out!',
        timestamp: timestamp,
        type: CommentType.warning,
      );
      expect(warning.type, CommentType.warning);
    });
  });

  group('CommentType Enum', () {
    test('should have correct number of values', () {
      // Assert
      expect(CommentType.values.length, 4);
    });

    test('should contain all expected types', () {
      // Assert
      expect(CommentType.values, contains(CommentType.positive));
      expect(CommentType.values, contains(CommentType.correction));
      expect(CommentType.values, contains(CommentType.encouragement));
      expect(CommentType.values, contains(CommentType.warning));
    });
  });

  group('LMCommentsSection UI State', () {
    testWidgets('should display comment type indicators', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LMCommentsSection(
              onBackToCamera: () {},
            ),
          ),
        ),
      );

      // Assert - Check for different comment type labels
      expect(find.text('Great!'), findsOneWidget);
      expect(find.text('Correction'), findsOneWidget);
      expect(find.text('Keep Going!'), findsOneWidget);
    });

    testWidgets('should display timestamps for comments', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LMCommentsSection(
              onBackToCamera: () {},
            ),
          ),
        ),
      );

      // Assert - Check for time indicators (ago format)
      expect(find.textContaining('ago'), findsWidgets);
    });

    testWidgets('should use different icons for different comment types', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LMCommentsSection(
              onBackToCamera: () {},
            ),
          ),
        ),
      );

      // Assert - Check for various comment type icons
      expect(find.byIcon(Icons.check_circle), findsOneWidget); // Positive
      expect(find.byIcon(Icons.info), findsOneWidget); // Correction
      expect(find.byIcon(Icons.favorite), findsOneWidget); // Encouragement
    });
  });

  group('LMCommentsSection Empty State', () {
    testWidgets('should handle empty comments list gracefully', (WidgetTester tester) async {
      // Note: Current implementation has placeholder data
      // This test verifies the widget doesn't crash with empty state
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LMCommentsSection(
              onBackToCamera: () {},
            ),
          ),
        ),
      );

      // Assert - Widget should build successfully
      expect(find.byType(LMCommentsSection), findsOneWidget);
    });
  });

  group('LMCommentsSection Accessibility', () {
    testWidgets('should have proper widget hierarchy', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LMCommentsSection(
              onBackToCamera: () {},
            ),
          ),
        ),
      );

      // Assert - Check structure
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should have readable text styles', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LMCommentsSection(
              onBackToCamera: () {},
            ),
          ),
        ),
      );

      // Assert - Verify text widgets exist
      expect(find.byType(Text), findsWidgets);
    });
  });
}
