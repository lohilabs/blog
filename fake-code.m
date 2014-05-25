- (void)viewDidLoad {
    [super viewDidLoad];
    // .. view configuration
    self.questionFullyLoaded = NO;
    self.inResultsView = NO;
    self.commentBoxView.hidden = YES;
    [self setupTextViewBackground];
        // refresh the question data
    [TCAPI getQuestionWithQuestionId:self.question.questionId 
                          onComplete:^(NSArray *objects, RKObjectRequestOperation *operation, NSError *error) {
        // ... table updates
        [sself updateViewCommentStatus];
        sself.questionFullyLoaded = YES;
        [self updateChangeAnswerButtonText];
    }];
}

- (IBAction)sendComment:(id)sender {
    TCShallowComment *comment = [[TCShallowComment alloc] init];
    // ... comment configuration
    [self.commentTextBox resignFirstResponder];
    // ... table updates

    [self updateViewCommentStatus];

    [TCAPI postComment:comment onComplete:^(NSArray *objects, RKObjectRequestOperation *operation, NSError *error) {
        //TODO: Handle error
        if (error) {
            self.question.totalCommentsValue -= 1;
        }
    }];
}