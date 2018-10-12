pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./Utils.sol";
import "./Eureka.sol";


contract EurekaPlatform {

    using SafeMath for uint256;

    Eureka eurekaTokenContract;

    address public contractOwner;

    /*
    *   journal parameters
    */

    // amount of rewarded reviewers
    uint minAmountOfEditorApprovedReviews = 2;
    uint maxAmountOfRewardedEditorApprovedReviews = 3;

    uint minAmountOfCommunityReviews = 0;
    uint maxAmountOfRewardedCommunityReviews = 10;

    // rewards amount
    uint sciencemattersFoundationReward = 1250;
    uint editorReward = 500;
    uint linkedArticlesReward = 750;
    uint invalidationWorkReward = 1000;

    uint editorApprovedReviewerRewardPerReviewer = 250;
    uint communityReviewerRewardPerReviewer = 50;
    uint secondReviewerRewardPerReviewer = 25;

    uint public submissionFee =
    sciencemattersFoundationReward
    + editorReward
    + linkedArticlesReward
    + invalidationWorkReward
    + maxAmountOfRewardedEditorApprovedReviews * editorApprovedReviewerRewardPerReviewer
    + maxAmountOfRewardedCommunityReviews * communityReviewerRewardPerReviewer
    + maxAmountOfRewardedCommunityReviews * secondReviewerRewardPerReviewer;

    uint constant maxReviewRounds = 3;

    function getJournalParameters() public returns (
        address _contractOwner,
        uint _minAmountOfEditorApprovedReviews,
        uint _maxAmountOfRewardedEditorApprovedReviews,
        uint _minAmountOfCommunityReviews,
        uint _maxAmountOfRewardedCommunityReviews,
        uint _sciencemattersFoundationReward,
        uint _editorReward,
        uint _linkedArticlesReward,
        uint _invalidationWorkReward,
        uint _editorApprovedReviewerRewardPerReviewer,
        uint _communityReviewerRewardPerReviewer,
        uint _secondReviewerRewardPerReviewer,
        uint _submissionFee,
        uint _maxReviewRounds
    ) {
        return (
        contractOwner,
        minAmountOfEditorApprovedReviews,
        maxAmountOfRewardedEditorApprovedReviews,
        minAmountOfCommunityReviews,
        maxAmountOfRewardedCommunityReviews,
        sciencemattersFoundationReward,
        editorReward,
        linkedArticlesReward,
        invalidationWorkReward,
        editorApprovedReviewerRewardPerReviewer,
        communityReviewerRewardPerReviewer,
        secondReviewerRewardPerReviewer,
        submissionFee,
        maxReviewRounds
        );
    }

    //    constructor(address _eurekaTokenContractAddress) public {
    constructor() public {

        //        eurekaTokenContract = Eureka(_eurekaTokenContractAddress);
        contractOwner = msg.sender;
    }


    mapping(address => bool) public isEditor;

    // primary key mappings
    uint256 submissionCounter;
    mapping(uint256 => ArticleSubmission) public articleSubmissions;
    mapping(bytes32 => ArticleVersion) public articleVersions;
    mapping(bytes32 => mapping(address => Review)) public  reviews;

    // address mappings
    //    mapping(address => ArticleVersion[]) articleVersionByAuthor;
    //    mapping(address => ArticleSubmission[]) articleSubmissionsByEditor;
    //    mapping(address => Review[]) reviewsByReviewer;


    enum SubmissionState {
        NOT_EXISTING,
        OPEN,
        EDITOR_ASSIGNED,
        NEW_REVIEW_ROUND_REQUESTED,
        CLOSED
    }
    // different ArticleVersion from different review-rounds are saved in the same ArticleSubmission Object
    struct ArticleSubmission {
        uint256 submissionId;
        SubmissionState submissionState;
        uint256 stateTimestamp;
        address submissionOwner;
        ArticleVersion[] versions;
        address editor;
    }

    enum ArticleVersionState {
        NOT_EXISTING,
        SUBMITTED,
        EDITOR_CHECKED,
        REVIEWERS_INVITED,
        NOT_ENOUGH_REVIEWERS,
        DECLINED_SANITY_NOTOK,
        DECLINED,
        ACCEPTED
    }

    // an ArticleSubmission can have different versions
    struct ArticleVersion {
        uint256 submissionId;
        bytes32 articleHash;
        // the timestamp when the article was published
        uint256 publishedTimestamp;
        // the URL where the article is saved
        //TODO: URL can be resp. IS USUALLY bigger than bytes32 -> us string and length indicator in bytes parser
        bytes32 articleUrl;

        ArticleVersionState versionState;
        uint256 stateTimestamp;

        address[] authors;
        // the submission owner can weight the contributions of the different authors [0;10000]
        //  ( e.g. 3 authors with 1/3 contribution each: {3334,3333,3333} )
        uint16[] authorContributionRatios;
        // the hashes of the linked articles
        bytes32[] linkedArticles;
        // the submission owner can weight the impact of the linked articles [0;10000]
        uint16[] linkedArticlesSplitRatios;

        // the reviewers which are allowed to review that article as an editor approved reviewer
        //        address[] allowedEditorApprovedReviewers;
        mapping(address => bool) allowedEditorApprovedReviewers;
        // the reviewers which are approved from the editor
        // TODO how to check if Reviewer already saved a review -> with array for loop (expensive) maybe save additional mapping
        //        mapping(address => Review) editorApprovedReviews;
        address[] editorApprovedReviews;

        // every community reviewer can add a community review without being approved
        // TODO how to check if Reviewer already saved a review -> with array for loop (expensive) maybe save additional mapping
        //        mapping(address => Review) communityReviews;
        address[] communityReviews;
    }

    enum ReviewState {
        NOT_EXISTING,
        INVITED,
        INVITATION_ACCEPTED,
        HANDED_IN,
        DECLINED,
        ACCEPTED
    }
    struct Review {
        bytes32 articleHash;
        address reviewer;

        bool isEditorApprovedReview;

        ReviewState reviewState;

        // with each state change the stateTimestamp field is updated
        uint256 stateTimestamp;

        bytes32 reviewHash;
        uint256 reviewedTimestamp;

        // if set to true, the editor cannot accept the article if he/she accepts this review
        bool articleHasMajorIssues;
        // acceptance of article is still possible although set to true
        bool articleHasMinorIssues;

        uint8 score1;
        uint8 score2;

        // address of the reviewer who reviewed this review (if at state ACCEPTED or DECLINED)
        address reviewedBy;
    }

    function getLinkedArticles(bytes32 hash) public view returns (bytes32[] linkedArticles) {
        linkedArticles = articleVersions[hash].linkedArticles;
    }

    function getAuthors(bytes32 hash) public view returns (address[] authors) {
        authors = articleVersions[hash].authors;
    }


    event EditorSignUp(address submissionOwner, address editorAddress, uint256 stateTimestamp);

    function signUpEditor(address editor) public {

        require(msg.sender == contractOwner, "msg.sender must be the contract owner to call this function");
        isEditor[editor] = true;
        emit EditorSignUp(msg.sender, editor, block.timestamp);
    }

    event SubmissionProcessStart(uint256 submissionId, address submissionOwner, bytes32 articleHash, bytes32 articleURL, uint256 stateTimestamp);

    function startSubmissionProcess(
        address _from,
        uint256 _value,
        bytes32 _articleHash, bytes32 _articleURL, address[] _authors,
        uint16[] _authorContributionRatios, bytes32[] _linkedArticles, uint16[] _linkedArticlesSplitRatios) public {

        //        require(msg.sender == address(eurekaTokenContract));
        require(_value == submissionFee, 'transferred amount needs to equal the submission fee');

        uint submissionId = submissionCounter++;
        ArticleSubmission storage submission = articleSubmissions[submissionId];

        submission.submissionId = submissionId;
        submission.submissionOwner = _from;

        submitArticleVersion(submissionId, _articleHash, _articleURL, _authors, _authorContributionRatios, _linkedArticles, _linkedArticlesSplitRatios);

        submission.submissionState = SubmissionState.OPEN;
        submission.stateTimestamp = block.timestamp;
        emit SubmissionProcessStart(submission.submissionId, submission.submissionOwner, _articleHash, _articleURL, block.timestamp);
    }

    function submitArticleVersion(uint256 _submissionId, bytes32 _articleHash, bytes32 _articleURL,
        address[] _authors, uint16[] _authorContributionRatios, bytes32[] _linkedArticles, uint16[] _linkedArticlesSplitRatios) private {

        ArticleVersion storage article = articleVersions[_articleHash];
        require(article.submissionId == 0, 'Article was already uploaded.');
        // edge case: two articles have the same hash

        article.submissionId = _submissionId;
        article.articleHash = _articleHash;
        article.articleUrl = _articleURL;
        article.publishedTimestamp = block.timestamp;

        article.authors = _authors;
        article.authorContributionRatios = _authorContributionRatios;
        article.linkedArticles = _linkedArticles;
        article.linkedArticlesSplitRatios = _linkedArticlesSplitRatios;

        articleSubmissions[_submissionId].versions.push(article);
        article.versionState = ArticleVersionState.SUBMITTED;
        article.stateTimestamp = block.timestamp;
    }


    event AssignmentForSubmissionProcess(address assignerAddress, uint256 submissionId);
    // a journal editor can assign him/herself to an article submission process
    // if the process is not already claimed by another editor
    function assignForSubmissionProcess(uint256 _submissionId) public {

        require(isEditor[msg.sender], "the sender of the transaction must be an editor to call this function.");

        ArticleSubmission storage submission = articleSubmissions[_submissionId];
        require(submission.submissionState == SubmissionState.OPEN, "the submission process needs to be OPEN to call this method.");
        require(submission.editor == address(0), "the submission process is already assigned to an editor.");
        require(msg.sender != submission.submissionOwner, "the submission owner can't be the editor of the same submission process");

        submission.editor = msg.sender;
        submission.submissionState = SubmissionState.EDITOR_ASSIGNED;
        submission.stateTimestamp = block.timestamp;
        emit AssignmentForSubmissionProcess(msg.sender, _submissionId);
    }

    event RemovedEditorFromSubmission(uint submissionId);

    function removeEditorFromSubmissionProcess(uint256 _submissionId) public {
        ArticleSubmission storage submission = articleSubmissions[_submissionId];

        require(submission.submissionState == SubmissionState.EDITOR_ASSIGNED, "an editor needs to be assigned to call this function.");
        require(msg.sender == contractOwner
        || msg.sender == submission.editor, "an editor can only be removed by the contract owner or itself.");

        submission.editor = address(0);
        submission.submissionState = SubmissionState.OPEN;
        submission.stateTimestamp = block.timestamp;
        emit RemovedEditorFromSubmission(_submissionId);
    }

    // is it a good idea that the current editor can assign another editor? or should only removing (method below) be possible?
    event ChangedEditorFromSubmission(uint256 submissionId, address newEditor);

    function changeEditorFromSubmissionProcess(uint256 _submissionId, address _newEditor) public {
        ArticleSubmission storage submission = articleSubmissions[_submissionId];
        require(submission.submissionState == SubmissionState.EDITOR_ASSIGNED, "an editor needs to be assigned to call this function.");
        require(isEditor[_newEditor], 'the new editor must be an allowed editor.');

        require(msg.sender == contractOwner
        || msg.sender == submission.editor, "an editor can only be changed by the contract owner or the current editor.");

        submission.editor = _newEditor;
        submission.stateTimestamp = block.timestamp;
        emit ChangedEditorFromSubmission(_submissionId, _newEditor);
    }

    event SanityIsOk(uint256 submissionId, bytes32 articleHash);

    function sanityIsOk(bytes32 _articleHash) public {

        require(articleSubmissions[articleVersions[_articleHash].submissionId].editor == msg.sender, "msg.sender must be the editor of this submission process");

        ArticleVersion storage article = articleVersions[_articleHash];
        require(article.versionState == ArticleVersionState.SUBMITTED, "this method can't be called. version state must be SUBMITTED.");

        article.versionState = ArticleVersionState.EDITOR_CHECKED;
        article.stateTimestamp = block.timestamp;
        emit SanityIsOk(articleVersions[_articleHash].submissionId, _articleHash);
    }

    event SanityIsNotOk(uint256 submissionId, bytes32 articleHash);

    function sanityIsNotOk(bytes32 _articleHash) public {

        require(articleSubmissions[articleVersions[_articleHash].submissionId].editor == msg.sender, "msg.sender must be the editor of this submission process");

        ArticleVersion storage article = articleVersions[_articleHash];
        require(article.versionState == ArticleVersionState.SUBMITTED, "this method can't be called. version state must be SUBMITTED.");

        article.versionState = ArticleVersionState.DECLINED_SANITY_NOTOK;
        article.stateTimestamp = block.timestamp;
        // TODO handle difference between review rounds and article versions, maybe not every new version is a review round, according to max Review rounds
        requestNewReviewRound(article.submissionId);
        emit SanityIsNotOk(articleVersions[_articleHash].submissionId, _articleHash);
    }

    event ReviewersAreInvited(uint256 submissionId, bytes32 articleHash, address[] editorApprovedReviewers, uint256 stateTimestamp);

    function inviteReviewers(bytes32 _articleHash, address[] _allowedEditorApprovedReviewers) public {

        require(articleSubmissions[articleVersions[_articleHash].submissionId].editor == msg.sender, "msg.sender must be the editor of this submission process");

        ArticleVersion storage article = articleVersions[_articleHash];
        require(article.versionState == ArticleVersionState.EDITOR_CHECKED, "this method can't be called. version state must be EDITOR_CHECKED.");

        for (uint i = 0; i < _allowedEditorApprovedReviewers.length; i++) {
            article.allowedEditorApprovedReviewers[_allowedEditorApprovedReviewers[i]] = true;
            reviews[_articleHash][_allowedEditorApprovedReviewers[i]].reviewState = ReviewState.INVITED;
            reviews[_articleHash][_allowedEditorApprovedReviewers[i]].stateTimestamp = block.timestamp;
        }
        article.versionState = ArticleVersionState.REVIEWERS_INVITED;
        article.stateTimestamp = block.timestamp;
        emit ReviewersAreInvited(articleVersions[_articleHash].submissionId, _articleHash, _allowedEditorApprovedReviewers, block.timestamp);
    }

    event InvitationIsAccepted(bytes32 articleHash, address reviewerAddress, uint256 stateTimestamp);

    function acceptReviewInvitation(bytes32 _articleHash) public {

        ArticleVersion storage article = articleVersions[_articleHash];
        require(article.versionState == ArticleVersionState.REVIEWERS_INVITED, "this method can't be called. version state must be REVIEWERS_INVITED.");

        //TODO: maybe not necessary anymore
        require(article.allowedEditorApprovedReviewers[msg.sender], "msg.sender is not invited to review");
        //TODO: handle accepted but not responding reviewers
        require(article.editorApprovedReviews.length < maxAmountOfRewardedEditorApprovedReviews, "the max amount of editor approved reviews is already reached.");

        Review storage review = reviews[_articleHash][msg.sender];
        require(review.reviewState == ReviewState.INVITED, "this method can't be called, the review state needs to be in INVITED.");
        review.reviewState = ReviewState.INVITATION_ACCEPTED;
        review.stateTimestamp = block.timestamp;
        review.reviewer = msg.sender;

        article.editorApprovedReviews.push(review.reviewer);
        emit InvitationIsAccepted(_articleHash, msg.sender, block.timestamp);
    }


    event EditorApprovedReviewIsAdded(bytes32 articleHash, uint256 stateTimestamp, bytes32 reviewHash, address reviewerAddress, bool articleHasMajorIssues, bool articleHasMinorIssues, uint8 score1, uint8 score2);

    function addEditorApprovedReview(bytes32 _articleHash, bytes32 _reviewHash, bool _articleHasMajorIssues, bool _articleHasMinorIssues, uint8 _score1, uint8 _score2) public {

        ArticleVersion storage article = articleVersions[_articleHash];
        require(article.versionState == ArticleVersionState.REVIEWERS_INVITED, "this method can't be called. version state must be REVIEWERS_INVITED.");

        //TODO: maybe not necessary anymore
        require(article.allowedEditorApprovedReviewers[msg.sender], "msg.sender is not invited to review");

        Review storage review = reviews[_articleHash][msg.sender];
        require(review.reviewState == ReviewState.INVITATION_ACCEPTED
        || review.reviewState == ReviewState.INVITED, "msg.sender is not authorized to add a editor approved revie");

        if (review.reviewState != ReviewState.INVITATION_ACCEPTED) {
            acceptReviewInvitation(_articleHash);
        }

        review.isEditorApprovedReview = true;
        review.reviewHash = _reviewHash;
        review.reviewedTimestamp = block.timestamp;
        review.articleHasMajorIssues = _articleHasMajorIssues;
        review.articleHasMinorIssues = _articleHasMinorIssues;
        review.score1 = _score1;
        review.score2 = _score2;

        review.reviewState = ReviewState.HANDED_IN;
        review.stateTimestamp = block.timestamp;
        emit EditorApprovedReviewIsAdded(_articleHash, block.timestamp, _reviewHash, review.reviewer, _articleHasMajorIssues, _articleHasMinorIssues, _score1, _score2);
    }

    event CommunityReviewIsAdded(bytes32 articleHash, uint256 stateTimestamp, bytes32 reviewHash, address reviewerAddress, bool articleHasMajorIssues, bool articleHasMinorIssues, uint8 score1, uint8 score2);

    function addCommunityReview(bytes32 _articleHash, bytes32 _reviewHash, bool _articleHasMajorIssues, bool _articleHasMinorIssues, uint8 _score1, uint8 _score2) public {

        ArticleVersion storage article = articleVersions[_articleHash];
        require(article.versionState == ArticleVersionState.SUBMITTED
        || article.versionState == ArticleVersionState.EDITOR_CHECKED
        || article.versionState == ArticleVersionState.REVIEWERS_INVITED
        , "this method can't be called. version state must be SUBMITTED, EDITOR_CHECKED or REVIEWERS_INVITED.");

        Review storage review = reviews[_articleHash][msg.sender];
        require(review.reviewState < ReviewState.HANDED_IN, "the review already exists.");

        review.reviewer = msg.sender;

        review.isEditorApprovedReview = false;
        review.reviewHash = _reviewHash;
        review.reviewedTimestamp = block.timestamp;
        review.articleHasMajorIssues = _articleHasMajorIssues;
        review.articleHasMinorIssues = _articleHasMinorIssues;
        review.score1 = _score1;
        review.score2 = _score2;

        article.communityReviews.push(review.reviewer);
        review.reviewState = ReviewState.HANDED_IN;
        review.stateTimestamp = block.timestamp;
        emit CommunityReviewIsAdded(_articleHash, block.timestamp, _reviewHash, review.reviewer, _articleHasMajorIssues, _articleHasMinorIssues, _score1, _score2);
    }

    event ReviewIsCorrected(bytes32 articleHash, uint256 stateTimestamp, bytes32 reviewHash, bool articleHasMajorIssues, bool articleHasMinorIssues, uint8 score1, uint8 score2);

    function correctReview(bytes32 _articleHash, bytes32 _reviewHash, bool _articleHasMajorIssues, bool _articleHasMinorIssues, uint8 _score1, uint8 _score2) public {

        ArticleVersion storage article = articleVersions[_articleHash];
        require(article.versionState == ArticleVersionState.SUBMITTED
        || article.versionState == ArticleVersionState.EDITOR_CHECKED
        || article.versionState == ArticleVersionState.REVIEWERS_INVITED, "this method can't be called. version state must be SUBMITTED, EDITOR_CHECKED or REVIEWERS_INVITED.");

        Review storage review = reviews[_articleHash][msg.sender];
        require(review.reviewState == ReviewState.DECLINED
        || review.reviewState == ReviewState.HANDED_IN, "only declined reviews can be corrected.");

        review.reviewHash = _reviewHash;
        review.reviewedTimestamp = block.timestamp;
        review.articleHasMajorIssues = _articleHasMajorIssues;
        review.articleHasMinorIssues = _articleHasMinorIssues;
        review.score1 = _score1;
        review.score2 = _score2;

        review.reviewState = ReviewState.HANDED_IN;
        review.stateTimestamp = block.timestamp;
        emit ReviewIsCorrected(_articleHash, block.timestamp, _reviewHash, _articleHasMajorIssues, _articleHasMinorIssues, _score1, _score2);
    }

    event ReviewIsAccepted(bytes32 articleHash, uint256 stateTimestamp, address reviewer);

    function acceptReview(bytes32 _articleHash, address _reviewerAddress) public {

        require(articleSubmissions[articleVersions[_articleHash].submissionId].editor == msg.sender, "msg.sender must be the editor of this submission process");

        //TODO: in which states of the articles the reviewers can hand in editorApprovedReviews and get accepted?
        ArticleVersion storage article = articleVersions[_articleHash];
        Review storage review = reviews[_articleHash][_reviewerAddress];
        if (review.isEditorApprovedReview)
            require(article.versionState == ArticleVersionState.REVIEWERS_INVITED, "this method can't be called. for accepting an editor approved review the article version state must be REVIEWERS_INVITED.");
        else
            require(article.versionState == ArticleVersionState.EDITOR_CHECKED, "this method can't be called. for accepting a community review the article version state must be EDITOR_CHECKED.");
        require(review.reviewState == ReviewState.HANDED_IN, "review state must be HANDED_IN.");

        review.reviewState = ReviewState.ACCEPTED;
        review.stateTimestamp = block.timestamp;
        review.reviewedBy = msg.sender;
        emit ReviewIsAccepted(_articleHash, block.timestamp, _reviewerAddress);
    }

    event ReviewIsDeclined(bytes32 articleHash, uint256 stateTimestamp, address reviewer);

    function declineReview(bytes32 _articleHash, address _reviewerAddress) public {

        require(articleSubmissions[articleVersions[_articleHash].submissionId].editor == msg.sender, "msg.sender must be the editor of this submission process");
        
        //TODO: in which states of the articles the reviewers can hand in editorApprovedReviews and get accepted?
        ArticleVersion storage article = articleVersions[_articleHash];
        Review storage review = reviews[_articleHash][_reviewerAddress];
        if (review.isEditorApprovedReview)
            require(article.versionState == ArticleVersionState.REVIEWERS_INVITED, "this method can't be called. for declining an editor approved review the article version state must be REVIEWERS_INVITED.");
        else
            require(article.versionState == ArticleVersionState.EDITOR_CHECKED, "this method can't be called. for declining a community review the article version state must be EDITOR_CHECKED.");
        require(review.reviewState == ReviewState.HANDED_IN, "review state must be HANDED_IN.");

        review.reviewState = ReviewState.DECLINED;
        review.stateTimestamp = block.timestamp;
        review.reviewedBy = msg.sender;
        emit ReviewIsDeclined(_articleHash, block.timestamp, _reviewerAddress);
    }


    // TODO     event EditorSignUp(address submissionOwner, address editorAddress, uint256 stateTimestamp);
    event ArticleVersionIsAccepted(bytes32 articleHash, uint256 stateTimestamp, address editor);

    function acceptArticleVersion(bytes32 _articleHash) public {

        require(isEditor[msg.sender], "msg.sender needs to be an editor.");
        // TODO  require(articleSubmissions[articleVersions[_articleHash].submissionId].editor == msg.sender, "msg.sender must be the editor of this submission process");

        ArticleVersion storage article = articleVersions[_articleHash];
        require(article.versionState == ArticleVersionState.REVIEWERS_INVITED, "this method can't be called. version state must be EDITOR_CHECKED.");

        require(countAcceptedReviews(article.articleHash, article.editorApprovedReviews) >= minAmountOfEditorApprovedReviews,
            "the article doesn't have enough accepted editor approved reviews to get accepted.");
        require(countAcceptedReviews(article.articleHash, article.communityReviews) >= minAmountOfCommunityReviews,
            "the article doesn't have enough community reviews to get accepted.");

        require(countAcceptedReviewInvitations(article.articleHash, article.editorApprovedReviews) == 0,
            "there are still people working on reviews.");

        require(countReviewsWithMajorIssues(article.articleHash, article.editorApprovedReviews) == 0,
            "the article needs to be corrected.");
        require(countReviewsWithMajorIssues(article.articleHash, article.communityReviews) == 0,
            "the article needs to be corrected.");

        article.versionState = ArticleVersionState.ACCEPTED;
        article.stateTimestamp = block.timestamp;

        //closeSubmissionProcess(article.submissionId);
        emit ArticleVersionIsAccepted(_articleHash, block.timestamp, msg.sender);
    }

    event DeclineArticleVersion(bytes32 articleHash, uint256 stateTimestamp, address editor);

    function declineArticleVersion(bytes32 _articleHash) public {

        require(isEditor[msg.sender], "msg.sender needs to be an editor.");

        ArticleVersion storage article = articleVersions[_articleHash];
        require(article.versionState == ArticleVersionState.REVIEWERS_INVITED, "this method can't be called. version state must be EDITOR_CHECKED.");


        require(countAcceptedReviews(article.articleHash, article.editorApprovedReviews) >= minAmountOfEditorApprovedReviews,
            "the article doesn't have enough accepted editor approved reviews to get accepted.");
        require(countAcceptedReviews(article.articleHash, article.communityReviews) >= minAmountOfCommunityReviews,
            "the article doesn't have enough community reviews to get accepted.");

        require(countAcceptedReviewInvitations(article.articleHash, article.editorApprovedReviews) == 0,
            "there are still people working on reviews.");

        article.versionState = ArticleVersionState.DECLINED;

        if (countDeclinedReviewRounds(article.submissionId) >= maxReviewRounds)
            closeSubmissionProcess(article.submissionId);
        else
            requestNewReviewRound(article.submissionId);

        emit DeclineArticleVersion(_articleHash, block.timestamp, msg.sender);
    }

    function countAcceptedReviewInvitations(bytes32 _articleHash, address[] _reviewers) view private returns (uint count) {
        for (uint i = 0; i < _reviewers.length; i++) {
            if (reviews[_articleHash][_reviewers[i]].reviewState == ReviewState.INVITATION_ACCEPTED)
                count++;
        }
        return count;
    }

    function countAcceptedReviews(bytes32 _articleHash, address[] _reviewers) view private returns (uint count) {
        count = 0;
        for (uint i = 0; i < _reviewers.length; i++) {
            if (reviews[_articleHash][_reviewers[i]].reviewState == ReviewState.ACCEPTED)
                count++;
        }
        return count;
    }

    function countReviewsWithMajorIssues(bytes32 _articleHash, address[] _reviewers) view private returns (uint count) {
        for (uint i = 0; i < _reviewers.length; i++) {
            if (reviews[_articleHash][_reviewers[i]].reviewState == ReviewState.ACCEPTED
            && reviews[_articleHash][_reviewers[i]].articleHasMajorIssues)
                count++;
        }
        return count;
    }

    // only counts the articles which went through a review process and therefore have the state DECLINED
    // does not consider the versions with state DECLINED_SANITY_NOTOK
    function countDeclinedReviewRounds(uint256 _submissionId) view private returns (uint count) {
        ArticleVersion[] storage versions = articleSubmissions[_submissionId].versions;
        for (uint i = 0; i < versions.length; i++) {
            if (versions[i].versionState == ArticleVersionState.DECLINED)
                count++;
        }
        return count;
    }

    event NewReviewRoundRequested(uint256 submissionId, uint256 stateTimestamp);
    function requestNewReviewRound(uint256 _submissionId) private {

        articleSubmissions[_submissionId].submissionState = SubmissionState.NEW_REVIEW_ROUND_REQUESTED;
        articleSubmissions[_submissionId].stateTimestamp = block.timestamp;
        emit NewReviewRoundRequested(_submissionId, block.timestamp);
    }

    event NewReviewRoundOpened(uint256 submissionId, bytes32 articleHash, bytes32 articleUrl, uint256 stateTimestamp);

    function openNewReviewRound(uint256 _submissionId, bytes32 _articleHash, bytes32 _articleURL, address[] _authors,
        uint16[] _authorContributionRatios, bytes32[] _linkedArticles, uint16[] _linkedArticlesSplitRatios) public {

        ArticleSubmission storage submission = articleSubmissions[_submissionId];
        require(msg.sender == submission.submissionOwner, "only the submission process owner can submit a new article version.");
        require(submission.submissionState == SubmissionState.NEW_REVIEW_ROUND_REQUESTED,
            "this method can't be called. the submission process state must be NEW_REVIEW_ROUND_REQUESTED.");

        submitArticleVersion(_submissionId, _articleHash, _articleURL, _authors, _authorContributionRatios, _linkedArticles, _linkedArticlesSplitRatios);

        submission.submissionState = SubmissionState.OPEN;
        submission.stateTimestamp = block.timestamp;
        emit NewReviewRoundOpened(_submissionId, _articleHash, _articleURL, block.timestamp);
    }

    event NewReviewRoundDeclined(uint256 submissionId, uint256 stateTimestamp);

    function declineNewReviewRound(uint256 _submissionId) public {

        ArticleSubmission storage submission = articleSubmissions[_submissionId];
        require(msg.sender == submission.submissionOwner, "only the submission process owner can call this method");
        require(submission.submissionState == SubmissionState.NEW_REVIEW_ROUND_REQUESTED,
            "this method can't be called. the submission process state must be NEW_REVIEW_ROUND_REQUESTED.");

        //closeSubmissionProcess(_submissionId);
        emit NewReviewRoundDeclined(_submissionId, block.timestamp);
    }

    // TODO: should it be possible to close a submission process before reaching maxReviewRounds ??
    function closeSubmissionProcess(uint256 _submissionId) private {

        ArticleSubmission submission = articleSubmissions[_submissionId];

        // transfer all rewards
        require(eurekaTokenContract.transfer(contractOwner, sciencemattersFoundationReward));
        require(eurekaTokenContract.transfer(submission.editor, editorReward));

        // counts how many reviewRounds happened to devide the reward later
        uint reviewRounds = countDeclinedReviewRounds(_submissionId) + 1;
        for (uint i = 0; i < submission.versions.length; i++) {
            if (submission.versions[i].versionState == ArticleVersionState.DECLINED
            || submission.versions[i].versionState == ArticleVersionState.ACCEPTED) {

                rewardEditorApprovedReviews(submission.versions[i], reviewRounds);
                rewardCommunityReviews(submission.versions[i], reviewRounds);
            }
        }

        if (submission.versions[submission.versions.length - 1].versionState == ArticleVersionState.ACCEPTED) {
            //TODO: reward linkedArticles authors and invalidation work
            // check also if time is already up
        }

        submission.submissionState = SubmissionState.CLOSED;
        submission.stateTimestamp = block.timestamp;
    }

    function rewardEditorApprovedReviews(ArticleVersion _articleVersion, uint _reviewRounds) private {
        uint rewardedReviewers = 0;
        for (uint i = 0; i < _articleVersion.editorApprovedReviews.length; i++) {
            if (rewardedReviewers < maxAmountOfRewardedEditorApprovedReviews) {
                if (reviews[_articleVersion.articleHash][_articleVersion.editorApprovedReviews[i]].reviewState == ReviewState.ACCEPTED) {
                    require(
                        eurekaTokenContract.transfer(
                            _articleVersion.editorApprovedReviews[i],
                            editorApprovedReviewerRewardPerReviewer.div(_reviewRounds)
                        ));
                    rewardedReviewers++;
                }
            }
            else
                return;
        }
    }

    function rewardCommunityReviews(ArticleVersion _articleVersion, uint _reviewRounds) private {
        uint rewardedReviewers = 0;
        for (uint i = 0; i < _articleVersion.communityReviews.length; i++) {
            if (rewardedReviewers < maxAmountOfRewardedCommunityReviews) {
                if (reviews[_articleVersion.articleHash][_articleVersion.communityReviews[i]].reviewState == ReviewState.ACCEPTED) {
                    require(
                        eurekaTokenContract.transfer(
                            _articleVersion.communityReviews[i],
                            communityReviewerRewardPerReviewer.div(_reviewRounds)
                        ));
                    require(
                        eurekaTokenContract.transfer(
                            reviews[_articleVersion.articleHash][_articleVersion.communityReviews[i]].reviewedBy,
                            secondReviewerRewardPerReviewer.div(_reviewRounds)
                        ));
                    rewardedReviewers++;
                }
            }
            else
                return;
        }
    }
}
