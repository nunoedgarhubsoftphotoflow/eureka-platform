import userService from '../db/user-service.mjs';
import articleSubmissionService from '../db/article-submission-service.mjs';
import reviewService from '../db/review-service.mjs';
import ArticleVersionState from '../schema/article-version-state-enum.mjs';

export default {
  setup: EurekaPlatformContract => {

    /** Editor Sign up **/
    EurekaPlatformContract.events.EditorSignUp(undefined, async (error, event) => {
      if (error) throw error;
      await userService.makeEditor(event.returnValues.editorAddress);
    });

    /** Submission Process Start **/
    EurekaPlatformContract.events.SubmissionProcessStart(
      undefined,
      async (error, event) => {
        if (error) throw error;
        await articleSubmissionService.createSubmission(
          event.returnValues.submissionId, event.returnValues.submissionOwner);
        await articleSubmissionService.submitArticleVersion(
          event.returnValues.submissionId,
          event.returnValues.articleHash,
          event.returnValues.articleURL
        );
      }
    );

    /** Assignement for Submission process **/
    EurekaPlatformContract.events.AssignmentForSubmissionProcess(
      undefined,
      (error, event) => {
        if (error) throw error;

        articleSubmissionService.updateEditorToSubmission(
          event.returnValues.submissionId,
          event.returnValues.assignerAddress
        );
      }
    );

    /** Remove editor from submission process **/
    EurekaPlatformContract.events.RemovedEditorFromSubmission(
      undefined,
      async (error, event) => {
        if (error) throw error;

        await articleSubmissionService.removeEditorFromSubmission(
          event.returnValues.submissionId
        );
      }
    );

    /** Change editor from submission process **/
    EurekaPlatformContract.events.ChangedEditorFromSubmission(
      undefined,
      async (error, event) => {
        if (error) throw error;

        await articleSubmissionService.updateEditorToSubmission(
          event.returnValues.submissionId,
          event.returnValues.newEditor
        );
      }
    );

    /** SanityCheck got accepted from an Editor on an article version **/
    EurekaPlatformContract.events.SanityIsOk(
      undefined,
      async (error, event) => {
        if (error) throw error;
        await articleSubmissionService.changeArticleVersionState(
          event.returnValues.submissionId,
          event.returnValues.articleHash,
          ArticleVersionState.EDITOR_CHECKED
        );
      }
    );

    /** SanityCheck got declined from an Editor on an article version **/
    EurekaPlatformContract.events.SanityIsNotOk(
      undefined,
      async (error, event) => {
        if (error) throw error;
        await articleSubmissionService.changeArticleVersionState(
          event.returnValues.submissionId,
          event.returnValues.articleHash,
          ArticleVersionState.DECLINED_SANITY_NOTOK
        );
      }
    );

    /** Reviewers are assigned as editor-approved on an article **/
    EurekaPlatformContract.events.ReviewersAreInvited(
      undefined,
      async (error, event) => {
        if (error) throw error;
        //TODO write in article-version --> reviewers
        const approvedReviewers = event.returnValues.editorApprovedReviewers;
        const submissionId = event.returnValues.submissionId;
        const articleHash = event.returnValues.articleHash;
        const timestamp = event.returnValues.stateTimestamp;

        // create reviews in ArticleVersion
        // for (let i = 0; i < approvedReviewers.length; i++) {
        //   console.log('APPROVED REVIEWER: ' + approvedReviewers[i]);
        //   let review = await reviewService.createReviewAndReturn(submissionId, articleHash, timestamp);
        //   articleSubmissionService.pushReviewIntoArticleVersion(submissionId, articleHash, review);
        //   //console.log(review);
        // }
        await articleSubmissionService.changeArticleVersionState(
          event.returnValues.submissionId,
          event.returnValues.articleHash,
          ArticleVersionState.REVIEWERS_INVITED
        );



        await createReviews(approvedReviewers, submissionId, articleHash, timestamp);

        //TODO write in user --> they are invited for become reviewer
        //TODO createReviews
      }
    );
  }
};

async function createReviews(approvedReviewers, submissionId, articleHash, timestamp) {
  approvedReviewers.forEach(async (approvedReviewer) => {
    await createReview(approvedReviewer, submissionId, articleHash, timestamp);
  });
}

async function createReview(reviewerAddress, submissionId, articleHash, timestamp) {
  console.log('AAADDDRESSS: ' +reviewerAddress);
  let review = await reviewService.createReviewAndReturn(submissionId, articleHash, timestamp, reviewerAddress);
  return await articleSubmissionService.pushReviewIntoArticleVersion(submissionId, articleHash, review);
}
