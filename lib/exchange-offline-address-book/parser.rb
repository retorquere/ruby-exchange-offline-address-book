#!/usr/bin/env ruby

require 'hashie'
require 'ostruct'

# https://github.com/intridea/hashie/pull/416
if Hashie::VERSION == '3.5.5'
  module Hashie
    class Mash
      def self.disable_warnings?
        @disable_warnings ||= false
      end
    end
  end
end

module Exchange
  module OfflineAddressBook

    class Record < ::Hashie::Mash
      include Hashie::Extensions::Mash::SymbolizeKeys
    end

    MapiPropertyDataType = OpenStruct.new({
      Unspecified: 0,
      Null: 1,
      Short: 2,
      Long: 3,
      Float: 4,
      Double: 5,
      Currency: 6,
      ApplicationTime: 7,
      Error: 10,
      Boolean: 11,
      Object: 13,
      LongLong: 20,
      AnsiString: 30,
      UnicodeString: 31,
      SystemTime: 64,
      Clsid: 72,
      Binary: 258,
      Mv: 0x1000 # Multi-value (aka array) flag
    })
    MapiPropertyDataType.MvShort = MapiPropertyDataType.Short | MapiPropertyDataType.Mv
    MapiPropertyDataType.MvLong = MapiPropertyDataType.Long | MapiPropertyDataType.Mv
    MapiPropertyDataType.MvFloat = MapiPropertyDataType.Float | MapiPropertyDataType.Mv
    MapiPropertyDataType.MvDouble = MapiPropertyDataType.Double | MapiPropertyDataType.Mv
    MapiPropertyDataType.MvCurrency = MapiPropertyDataType.Currency | MapiPropertyDataType.Mv
    MapiPropertyDataType.MvApplicationTime = MapiPropertyDataType.ApplicationTime | MapiPropertyDataType.Mv
    MapiPropertyDataType.MvLongLong = MapiPropertyDataType.LongLong | MapiPropertyDataType.Mv
    MapiPropertyDataType.MvAnsiString = MapiPropertyDataType.AnsiString | MapiPropertyDataType.Mv
    MapiPropertyDataType.MvUnicodeString = MapiPropertyDataType.UnicodeString | MapiPropertyDataType.Mv
    MapiPropertyDataType.MvSystemTime = MapiPropertyDataType.SystemTime | MapiPropertyDataType.Mv
    MapiPropertyDataType.MvClsid = MapiPropertyDataType.Clsid | MapiPropertyDataType.Mv
    MapiPropertyDataType.MvBinary = MapiPropertyDataType.Binary | MapiPropertyDataType.Mv
    MapiPropertyDataType.to_h.each_pair{|k, v| MapiPropertyDataType[v.to_s.to_sym] = k }

    MapiPropertyName = {
      '0001' => :TemplateData,
      '0002' => :AlternateRecipientAllowed,
      '0004' => :AutoForwardComment,
    # '0004' => :ScriptData,
      '0005' => :AutoForwarded,
      '000F' => :DeferredDeliveryTime,
      '0015' => :ExpiryTime,
      '0017' => :Importance,
      '001A' => :MessageClass,
      '0023' => :OriginatorDeliveryReportRequested,
      '0025' => :ParentKey,
      '0026' => :Priority,
      '0029' => :ReadReceiptRequested,
      '002B' => :RecipientReassignmentProhibited,
      '002E' => :OriginalSensitivity,
      '0030' => :ReplyTime,
      '0031' => :ReportTag,
      '0032' => :ReportTime,
      '0036' => :Sensitivity,
      '0037' => :Subject,
      '0039' => :ClientSubmitTime,
      '003A' => :ReportName,
      '003B' => :SentRepresentingSearchKey,
      '003D' => :SubjectPrefix,
      '003F' => :ReceivedByEntryId,
      '0040' => :ReceivedByName,
      '0041' => :SentRepresentingEntryId,
      '0042' => :SentRepresentingName,
      '0043' => :ReceivedRepresentingEntryId,
      '0044' => :ReceivedRepresentingName,
      '0045' => :ReportEntryId,
      '0046' => :ReadReceiptEntryId,
      '0047' => :MessageSubmissionId,
      '0048' => :ProviderSubmitTime,
      '0049' => :OriginalSubject,
      '004B' => :OriginalMessageClass,
      '004C' => :OriginalAuthorEntryId,
      '004D' => :OriginalAuthorName,
      '004E' => :OriginalSubmitTime,
      '004F' => :ReplyRecipientEntries,
      '0050' => :ReplyRecipientNames,
      '0051' => :ReceivedBySearchKey,
      '0052' => :ReceivedRepresentingSearchKey,
      '0053' => :ReadReceiptSearchKey,
      '0054' => :ReportSearchKey,
      '0055' => :OriginalDeliveryTime,
      '0057' => :MessageToMe,
      '0058' => :MessageCcMe,
      '0059' => :MessageRecipientMe,
      '005A' => :OriginalSenderName,
      '005B' => :OriginalSenderEntryId,
      '005C' => :OriginalSenderSearchKey,
      '005D' => :OriginalSentRepresentingName,
      '005E' => :OriginalSentRepresentingEntryId,
      '005F' => :OriginalSentRepresentingSearchKey,
      '0060' => :StartDate,
      '0061' => :EndDate,
      '0062' => :OwnerAppointmentId,
      '0063' => :ResponseRequested,
      '0064' => :SentRepresentingAddressType,
      '0065' => :SentRepresentingEmailAddress,
      '0066' => :OriginalSenderAddressType,
      '0067' => :OriginalSenderEmailAddress,
      '0068' => :OriginalSentRepresentingAddressType,
      '0069' => :OriginalSentRepresentingEmailAddress,
      '0070' => :ConversationTopic,
      '0071' => :ConversationIndex,
      '0072' => :OriginalDisplayBcc,
      '0073' => :OriginalDisplayCc,
      '0074' => :OriginalDisplayTo,
      '0075' => :ReceivedByAddressType,
      '0076' => :ReceivedByEmailAddress,
      '0077' => :ReceivedRepresentingAddressType,
      '0078' => :ReceivedRepresentingEmailAddress,
      '007D' => :TransportMessageHeaders,
      '007F' => :TnefCorrelationKey,
      '0080' => :ReportDisposition,
      '0081' => :ReportDispositionMode,
      '0807' => :AddressBookRoomCapacity,
      '0809' => :AddressBookRoomDescription,
      '0C06' => :NonReceiptNotificationRequested,
      '0C08' => :OriginatorNonDeliveryReportRequested,
      '0C15' => :RecipientType,
      '0C17' => :ReplyRequested,
      '0C19' => :SenderEntryId,
      '0C1A' => :SenderName,
      '0C1D' => :SenderSearchKey,
      '0C1E' => :SenderAddressType,
      '0C1F' => :SenderEmailAddress,
      '0E01' => :DeleteAfterSubmit,
      '0E02' => :DisplayBcc,
      '0E03' => :DisplayCc,
      '0E04' => :DisplayTo,
      '0E06' => :MessageDeliveryTime,
      '0E07' => :MessageFlags,
      '0E08' => :MessageSize,
    # '0E08' => :MessageSizeExtended,
      '0E09' => :ParentEntryId,
      '0E0F' => :Responsibility,
      '0E12' => :MessageRecipients,
      '0E13' => :MessageAttachments,
      '0E17' => :MessageStatus,
      '0E1B' => :HasAttachments,
      '0E1D' => :NormalizedSubject,
      '0E1F' => :RtfInSync,
      '0E20' => :AttachSize,
      '0E21' => :AttachNumber,
      '0E23' => :InternetArticleNumber,
      '0E28' => :PrimarySendAccount,
      '0E29' => :NextSendAcct,
      '0E2B' => :ToDoItemFlags,
      '0E2C' => :SwappedToDoStore,
      '0E2D' => :SwappedToDoData,
      '0E69' => :Read,
      '0E6A' => :SecurityDescriptorAsXml,
      '0E79' => :TrustSender,
      '0E84' => :ExchangeNTSecurityDescriptor,
      '0E99' => :ExtendedRuleMessageActions,
      '0E9A' => :ExtendedRuleMessageCondition,
      '0E9B' => :ExtendedRuleSizeLimit,
      '0FF4' => :Access,
      '0FF5' => :RowType,
      '0FF6' => :InstanceKey,
      '0FF7' => :AccessLevel,
      '0FF8' => :MappingSignature,
      '0FF9' => :RecordKey,
      '0FFB' => :StoreEntryId,
      '0FFE' => :ObjectType,
      '0FFF' => :EntryId,
      '1000' => :Body,
      '1001' => :ReportText,
      '1009' => :RtfCompressed,
      '1013' => :BodyHtml,
    # '1013' => :Html,
      '1014' => :BodyContentLocation,
      '1015' => :BodyContentId,
      '1016' => :NativeBody,
      '1035' => :InternetMessageId,
      '1039' => :InternetReferences,
      '1042' => :InReplyToId,
      '1043' => :ListHelp,
      '1044' => :ListSubscribe,
      '1045' => :ListUnsubscribe,
      '1046' => :OriginalMessageId,
      '1080' => :IconIndex,
      '1081' => :LastVerbExecuted,
      '1082' => :LastVerbExecutionTime,
      '1090' => :FlagStatus,
      '1091' => :FlagCompleteTime,
      '1095' => :FollowupIcon,
      '1096' => :BlockStatus,
      '10C3' => :ICalendarStartTime,
      '10C4' => :ICalendarEndTime,
      '10C5' => :CdoRecurrenceid,
      '10CA' => :ICalendarReminderNextTime,
      '10F3' => :UrlCompName,
      '10F4' => :AttributeHidden,
      '10F6' => :AttributeReadOnly,
      '3000' => :Rowid,
      '3001' => :DisplayName,
      '3002' => :AddressType,
      '3003' => :EmailAddress,
      '3004' => :Comment,
      '3005' => :Depth,
      '3007' => :CreationTime,
      '3008' => :LastModificationTime,
      '300B' => :SearchKey,
      '3010' => :TargetEntryId,
      '3013' => :ConversationId,
      '3016' => :ConversationIndexTracking,
      '3018' => :ArchiveTag,
      '3019' => :PolicyTag,
      '301A' => :RetentionPeriod,
      '301B' => :StartDateEtc,
      '301C' => :RetentionDate,
      '301D' => :RetentionFlags,
      '301E' => :ArchivePeriod,
      '301F' => :ArchiveDate,
      '340D' => :StoreSupportMask,
      '340E' => :StoreState,
      '3600' => :ContainerFlags,
      '3601' => :FolderType,
      '3602' => :ContentCount,
      '3603' => :ContentUnreadCount,
      '3609' => :Selectable,
      '360A' => :Subfolders,
      '360C' => :Anr,
      '360E' => :ContainerHierarchy,
      '360F' => :ContainerContents,
      '3610' => :FolderAssociatedContents,
      '3613' => :ContainerClass,
      '36D0' => :IpmAppointmentEntryId,
      '36D1' => :IpmContactEntryId,
      '36D2' => :IpmJournalEntryId,
      '36D3' => :IpmNoteEntryId,
      '36D4' => :IpmTaskEntryId,
      '36D5' => :RemindersOnlineEntryId,
      '36D7' => :IpmDraftsEntryId,
      '36D8' => :AdditionalRenEntryIds,
      '36D9' => :AdditionalRenEntryIdsEx,
      '36DA' => :ExtendedFolderFlags,
      '36E2' => :OrdinalMost,
      '36E4' => :FreeBusyEntryIds,
      '36E5' => :DefaultPostMessageClass,
      '3701' => :AttachDataObject,
    # '3701' => :AttachDataBinary,
      '3702' => :AttachEncoding,
      '3703' => :AttachExtension,
      '3704' => :AttachFilename,
      '3705' => :AttachMethod,
      '3707' => :AttachLongFilename,
      '3708' => :AttachPathname,
      '3709' => :AttachRendering,
      '370A' => :AttachTag,
      '370B' => :RenderingPosition,
      '370C' => :AttachTransportName,
      '370D' => :AttachLongPathname,
      '370E' => :AttachMimeTag,
      '370F' => :AttachAdditionalInformation,
      '3711' => :AttachContentBase,
      '3712' => :CID,
      '3713' => :AttachContentLocation,
      '3714' => :AttachFlags,
      '3719' => :AttachPayloadProviderGuidString,
      '371A' => :AttachPayloadClass,
      '371B' => :TextAttachmentCharset,
      '3900' => :DisplayType,
      '3902' => :Templateid,
      '3905' => :DisplayTypeEx,
      '39FE' => :SmtpAddress,
      '39FF' => :AddressBookDisplayNamePrintable,
      '3A00' => :Account,
      '3A02' => :CallbackTelephoneNumber,
      '3A05' => :Generation,
      '3A06' => :GivenName,
      '3A07' => :GovernmentIdNumber,
      '3A08' => :BusinessTelephoneNumber,
      '3A09' => :HomeTelephoneNumber,
      '3A0A' => :Initials,
      '3A0B' => :Keyword,
      '3A0C' => :Language,
      '3A0D' => :Location,
      '3A0F' => :MessageHandlingSystemCommonName,
      '3A10' => :OrganizationalIdNumber,
      '3A11' => :Surname,
      '3A12' => :OriginalEntryId,
      '3A15' => :PostalAddress,
      '3A16' => :CompanyName,
      '3A17' => :Title,
      '3A18' => :DepartmentName,
      '3A19' => :OfficeLocation,
      '3A1A' => :PrimaryTelephoneNumber,
      '3A1B' => :Business2TelephoneNumber,
    # '3A1B' => :Business2TelephoneNumbers,
      '3A1C' => :MobileTelephoneNumber,
      '3A1D' => :RadioTelephoneNumber,
      '3A1E' => :CarTelephoneNumber,
      '3A1F' => :OtherTelephoneNumber,
      '3A20' => :TransmittableDisplayName,
      '3A21' => :PagerTelephoneNumber,
      '3A22' => :UserCertificate,
      '3A23' => :PrimaryFaxNumber,
      '3A24' => :BusinessFaxNumber,
      '3A25' => :HomeFaxNumber,
      '3A26' => :Country,
      '3A27' => :Locality,
      '3A28' => :StateOrProvince,
      '3A29' => :StreetAddress,
      '3A2A' => :PostalCode,
      '3A2B' => :PostOfficeBox,
      '3A2C' => :TelexNumber,
      '3A2D' => :IsdnNumber,
      '3A2E' => :AssistantTelephoneNumber,
      '3A2F' => :Home2TelephoneNumber,
    # '3A2F' => :Home2TelephoneNumbers,
      '3A30' => :Assistant,
      '3A40' => :SendRichInfo,
      '3A41' => :WeddingAnniversary,
      '3A42' => :Birthday,
      '3A43' => :Hobbies,
      '3A44' => :MiddleName,
      '3A45' => :DisplayNamePrefix,
      '3A46' => :Profession,
      '3A47' => :ReferredByName,
      '3A48' => :SpouseName,
      '3A49' => :ComputerNetworkName,
      '3A4A' => :CustomerId,
      '3A4B' => :TelecommunicationsDeviceForDeafTelephoneNumber,
      '3A4C' => :FtpSite,
      '3A4D' => :Gender,
      '3A4E' => :ManagerName,
      '3A4F' => :Nickname,
      '3A50' => :PersonalHomePage,
      '3A51' => :BusinessHomePage,
      '3A57' => :CompanyMainTelephoneNumber,
      '3A58' => :ChildrensNames,
      '3A59' => :HomeAddressCity,
      '3A5A' => :HomeAddressCountry,
      '3A5B' => :HomeAddressPostalCode,
      '3A5C' => :HomeAddressStateOrProvince,
      '3A5D' => :HomeAddressStreet,
      '3A5E' => :HomeAddressPostOfficeBox,
      '3A5F' => :OtherAddressCity,
      '3A60' => :OtherAddressCountry,
      '3A61' => :OtherAddressPostalCode,
      '3A62' => :OtherAddressStateOrProvince,
      '3A63' => :OtherAddressStreet,
      '3A64' => :OtherAddressPostOfficeBox,
      '3A70' => :UserX509Certificate,
      '3A71' => :SendInternetEncoding,
      '3F08' => :InitialDetailsPane,
      '3F20' => :TemporaryDefaultDocument,
      '3FDE' => :InternetCodepage,
      '3FDF' => :AutoResponseSuppress,
      '3FE0' => :AccessControlListData,
      '3FE3' => :DelegatedByRule,
      '3FE7' => :ResolveMethod,
      '3FEA' => :HasDeferredActionMessages,
      '3FEB' => :DeferredSendNumber,
      '3FEC' => :DeferredSendUnits,
      '3FED' => :ExpiryNumber,
      '3FEE' => :ExpiryUnits,
      '3FEF' => :DeferredSendTime,
      '3FF0' => :ConflictEntryId,
      '3FF1' => :MessageLocaleId,
      '3FF8' => :CreatorName,
      '3FF9' => :CreatorEntryId,
      '3FFA' => :LastModifierName,
      '3FFB' => :LastModifierEntryId,
      '3FFD' => :MessageCodepage,
      '401A' => :SentRepresentingFlags,
      '4029' => :ReadReceiptAddressType,
      '402A' => :ReadReceiptEmailAddress,
      '402B' => :ReadReceiptName,
      '4076' => :ContentFilterSpamConfidenceLevel,
      '4079' => :SenderIdStatus,
      '4083' => :PurportedSenderDomain,
      '5902' => :InternetMailOverrideFormat,
      '5909' => :MessageEditorFormat,
      '5D01' => :SenderSmtpAddress,
      '5FDE' => :RecipientResourceState,
      '5FDF' => :RecipientOrder,
      '5FE1' => :RecipientProposed,
      '5FE3' => :RecipientProposedStartTime,
      '5FE4' => :RecipientProposedEndTime,
      '5FF6' => :RecipientDisplayName,
      '5FF7' => :RecipientEntryId,
      '5FFB' => :RecipientTrackStatusTime,
      '5FFD' => :RecipientFlags,
      '5FFF' => :RecipientTrackStatus,
      '6100' => :JunkIncludeContacts,
      '6101' => :JunkThreshold,
      '6102' => :JunkPermanentlyDelete,
      '6103' => :JunkAddRecipientsToSafeSendersList,
      '6107' => :JunkPhishingEnableLinks,
      '64F0' => :MimeSkeleton,
      '65C2' => :ReplyTemplateId,
      '65E0' => :SourceKey,
      '65E1' => :ParentSourceKey,
      '65E2' => :ChangeKey,
      '65E3' => :PredecessorChangeList,
      '65E9' => :RuleMessageState,
      '65EA' => :RuleMessageUserFlags,
      '65EB' => :RuleMessageProvider,
      '65EC' => :RuleMessageName,
      '65ED' => :RuleMessageLevel,
      '65EE' => :RuleMessageProviderData,
      '65F3' => :RuleMessageSequence,
      '6619' => :UserEntryId,
      '661B' => :MailboxOwnerEntryId,
      '661C' => :MailboxOwnerName,
      '661D' => :OutOfOfficeState,
      '6622' => :ScheduleFreeBusy,
      '6639' => :Rights,
      '663A' => :HasRules,
      '663B' => :AddressBookEntryId,
      '663E' => :HierarchyChangeNumber,
      '6645' => :ClientActions,
      '6646' => :DamOriginalEntryId,
      '6647' => :DamBackPatched,
      '6648' => :RuleError,
      '6649' => :RuleActionType,
      '664A' => :HasNamedProperties,
      '6650' => :RuleActionNumber,
      '6651' => :RuleFolderEntryId,
      '666A' => :ProhibitReceiveQuota,
      '666C' => :InConflict,
      '666D' => :MaximumSubmitMessageSize,
      '666E' => :ProhibitSendQuota,
      '6671' => :MemberId,
      '6672' => :MemberName,
      '6673' => :MemberRights,
      '6674' => :RuleId,
      '6675' => :RuleIds,
      '6676' => :RuleSequence,
      '6677' => :RuleState,
      '6678' => :RuleUserFlags,
      '6679' => :RuleCondition,
      '6680' => :RuleActions,
      '6681' => :RuleProvider,
      '6682' => :RuleName,
      '6683' => :RuleLevel,
      '6684' => :RuleProviderData,
      '668F' => :DeletedOn,
      '66A1' => :LocaleId,
      '66B3' => :NormalMessageSize,
      '66C3' => :CodePageId,
      '6704' => :AddressBookManageDistributionList,
      '6705' => :SortLocaleId,
      '6707' => :UrlName,
      '6708' => :Subfolder,
      '6709' => :LocalCommitTime,
      '670A' => :LocalCommitTimeMax,
      '670B' => :DeletedCountTotal,
      '670E' => :FlatUrlName,
      '671C' => :PublicFolderAdministrativeDescription,
      '671D' => :PublicFolderProxy,
      '6740' => :SentMailSvrEID,
      '6741' => :DeferredActionMessageOriginalEntryId,
      '6748' => :FolderId,
      '6749' => :ParentFolderId,
      '674A' => :Mid,
      '674D' => :InstID,
      '674E' => :InstanceNum,
      '674F' => :AddressBookMessageId,
      '67A4' => :ChangeNumber,
      '67AA' => :Associated,
      '6800' => :OfflineAddressBookName,
      '6801' => :OfflineAddressBookSequence,
    # '6801' => :VoiceMessageDuration,
      '6802' => :OfflineAddressBookContainerGuid,
    # '6802' => :SenderTelephoneNumber,
    # '6802' => :RwRulesStream,
      '6803' => :OfflineAddressBookMessageClass,
    # '6803' => :VoiceMessageSenderName,
      '6804' => :FaxNumberOfPages,
    # '6804' => :OfflineAddressBookDistinguishedName,
      '6805' => :VoiceMessageAttachmentOrder,
    # '6805' => :OfflineAddressBookTruncatedProperties,
      '6806' => :CallId,
      '6834' => :SearchFolderLastUsed,
      '683A' => :SearchFolderExpiration,
      '6841' => :ScheduleInfoResourceType,
    # '6841' => :SearchFolderTemplateId,
      '6842' => :ScheduleInfoDelegatorWantsCopy,
    # '6842' => :SearchFolderId,
    # '6842' => :WlinkGroupHeaderID,
      '6843' => :ScheduleInfoDontMailDelegates,
      '6844' => :SearchFolderRecreateInfo,
    # '6844' => :ScheduleInfoDelegateNames,
      '6845' => :SearchFolderDefinition,
    # '6845' => :ScheduleInfoDelegateEntryIds,
      '6846' => :SearchFolderStorageType,
    # '6846' => :GatewayNeedsToRefresh,
      '6847' => :FreeBusyPublishStart,
    # '6847' => :SearchFolderTag,
    # '6847' => :WlinkSaveStamp,
      '6848' => :FreeBusyPublishEnd,
    # '6848' => :SearchFolderEfpFlags,
      '6849' => :WlinkType,
    # '6849' => :FreeBusyMessageEmailAddress,
      '684A' => :WlinkFlags,
    # '684A' => :ScheduleInfoDelegateNamesW,
      '684B' => :ScheduleInfoDelegatorWantsInfo,
    # '684B' => :WlinkOrdinal,
      '684C' => :WlinkEntryId,
      '684D' => :WlinkRecordKey,
      '684E' => :WlinkStoreEntryId,
      '684F' => :WlinkFolderType,
    # '684F' => :ScheduleInfoMonthsMerged,
      '6850' => :WlinkGroupClsid,
    # '6850' => :ScheduleInfoFreeBusyMerged,
      '6851' => :WlinkGroupName,
    # '6851' => :ScheduleInfoMonthsTentative,
      '6852' => :WlinkSection,
    # '6852' => :ScheduleInfoFreeBusyTentative,
      '6853' => :WlinkCalendarColor,
    # '6853' => :ScheduleInfoMonthsBusy,
      '6854' => :WlinkAddressBookEID,
    # '6854' => :ScheduleInfoFreeBusyBusy,
      '6855' => :ScheduleInfoMonthsAway,
      '6856' => :ScheduleInfoFreeBusyAway,
      '6868' => :FreeBusyRangeTimestamp,
      '6869' => :FreeBusyCountMonths,
      '686A' => :ScheduleInfoAppointmentTombstone,
      '686B' => :DelegateFlags,
      '686C' => :ScheduleInfoFreeBusy,
      '686D' => :ScheduleInfoAutoAcceptAppointments,
      '686F' => :ScheduleInfoDisallowOverlappingAppts,
      '6890' => :WlinkClientID,
      '6891' => :WlinkAddressBookStoreEID,
      '6892' => :WlinkROGroupType,
      '7001' => :ViewDescriptorBinary,
      '7002' => :ViewDescriptorStrings,
      '7006' => :ViewDescriptorName,
      '7007' => :ViewDescriptorVersion,
      '7C06' => :RoamingDatatypes,
      '7C07' => :RoamingDictionary,
      '7C08' => :RoamingXmlStream,
      '7C24' => :OscSyncEnabled,
      '7D01' => :Processed,
      '7FF9' => :ExceptionReplaceTime,
      '7FFA' => :AttachmentLinkId,
      '7FFB' => :ExceptionStartTime,
      '7FFC' => :ExceptionEndTime,
      '7FFD' => :AttachmentFlags,
      '7FFE' => :AttachmentHidden,
      '7FFF' => :AttachmentContactPhoto,
      '8004' => :AddressBookFolderPathname,
      '8005' => :AddressBookManager,
    # '8005' => :AddressBookManagerDistinguishedName,
      '8006' => :AddressBookHomeMessageDatabase,
      '8008' => :AddressBookIsMemberOfDistributionList,
      '8009' => :AddressBookMember,
      '800C' => :AddressBookOwner,
      '800E' => :AddressBookReports,
      '800F' => :AddressBookProxyAddresses,
      '8011' => :AddressBookTargetAddress,
      '8015' => :AddressBookPublicDelegates,
      '8024' => :AddressBookOwnerBackLink,
      '802D' => :AddressBookExtensionAttribute1,
      '802E' => :AddressBookExtensionAttribute2,
      '802F' => :AddressBookExtensionAttribute3,
      '8030' => :AddressBookExtensionAttribute4,
      '8031' => :AddressBookExtensionAttribute5,
      '8032' => :AddressBookExtensionAttribute6,
      '8033' => :AddressBookExtensionAttribute7,
      '8034' => :AddressBookExtensionAttribute8,
      '8035' => :AddressBookExtensionAttribute9,
      '8036' => :AddressBookExtensionAttribute10,
      '803C' => :AddressBookObjectDistinguishedName,
      '806A' => :AddressBookDeliveryContentLength,
      '8073' => :AddressBookDistributionListMemberSubmitAccepted,
      '8170' => :AddressBookNetworkAddress,
      '8C57' => :AddressBookExtensionAttribute11,
      '8C58' => :AddressBookExtensionAttribute12,
      '8C59' => :AddressBookExtensionAttribute13,
      '8C60' => :AddressBookExtensionAttribute14,
      '8C61' => :AddressBookExtensionAttribute15,
      '8C6A' => :AddressBookX509Certificate,
      '8C6D' => :AddressBookObjectGuid,
      '8C8E' => :AddressBookPhoneticGivenName,
      '8C8F' => :AddressBookPhoneticSurname,
      '8C90' => :AddressBookPhoneticDepartmentName,
      '8C91' => :AddressBookPhoneticCompanyName,
      '8C92' => :AddressBookPhoneticDisplayName,
      '8C93' => :AddressBookDisplayTypeExtended,
      '8C94' => :AddressBookHierarchicalShowInDepartments,
      '8C96' => :AddressBookRoomContainers,
      '8C97' => :AddressBookHierarchicalDepartmentMembers,
      '8C98' => :AddressBookHierarchicalRootDepartment,
      '8C99' => :AddressBookHierarchicalParentDepartment,
      '8C9A' => :AddressBookHierarchicalChildDepartments,
      '8C9E' => :ThumbnailPhoto,
      '8CA0' => :AddressBookSeniorityIndex,
      '8CA8' => :AddressBookOrganizationalUnitRootDistinguishedName,
      '8CAC' => :AddressBookSenderHintTranslations,
      '8CB5' => :AddressBookModerationEnabled,
      '8CC2' => :SpokenName,
      '8CD8' => :AddressBookAuthorizedSenders,
      '8CD9' => :AddressBookUnauthorizedSenders,
      '8CDA' => :AddressBookDistributionListMemberSubmitRejected,
      '8CDB' => :AddressBookDistributionListRejectMessagesFromDLMembers,
      '8CDD' => :AddressBookHierarchicalIsHierarchicalGroup,
      '8CE2' => :AddressBookDistributionListMemberCount,
      '8CE3' => :AddressBookDistributionListExternalMemberCount,
      'FFFB' => :AddressBookIsMaster,
      'FFFC' => :AddressBookParentEntryId,
      'FFFD' => :AddressBookContainerId,
    }

    class Parser
      def initialize(oab)
        @oab = open(oab)
        @header = _header
      end

      def pos
        return sprintf('%08o', @oab.pos)
      end
      def typeof(type)
        return MapiPropertyDataType[type.to_s.to_sym]
      end

      attr_reader :serialNumber, :totalRecords, :header

      def _uint32
        return @oab.read(4).unpack('V*')[0]
      end
      def _ubyte
        return @oab.read(1).unpack('C*')[0]
      end

      def _integer
        firstByte = _ubyte

        return firstByte if firstByte < 0x80

        case firstByte
          when 0x81 then return _ubyte
          when 0x82 then return _ubyte + (_ubyte << 8)
          when 0x83 then return _ubyte + (_ubyte << 8) + (_ubyte << 16)
          when 0x84 then return _ubyte + (_ubyte << 8) + (_ubyte << 16) + (_ubyte << 24)
        end
        raise "Unexpected first byte #{sprintf('%x', firstByte)} of integer"
      end

      def _propertyTypes
        n = _uint32
        return 1.upto(n).collect{|i|
          prop = OpenStruct.new
          prop.pos = pos

          id = _uint32
          prop._id = id.to_s(16)
          prop.id = sprintf('%04x', id >> 16).upcase
          prop.name = MapiPropertyName[prop.id]
          throw prop.id unless prop.name && prop.name != ''
          type = id & 0xffff
          prop.type = typeof(type & ~MapiPropertyDataType.Mv)
          prop._type = sprintf('%04x', (type & ~MapiPropertyDataType.Mv))
          prop.array = ((type & MapiPropertyDataType.Mv) != 0)
          prop.flags = _uint32
          prop
        }
      end

      def _header
        # Read OAB_HDR
        version = _uint32
        raise "Version not found, got #{version.inspect}" unless version == 0x20 # version
        @serialNumber = _uint32
        @totalRecords = _uint32
        # Read OAB_META_DATA
        metadataSize = _uint32

        @headerProperties = _propertyTypes
        @oabProperties = _propertyTypes
        return _record(true)
      end

      def _property(prop)
        if prop.array
          valueCount = _integer
          value = []
          valueCount.times{
            value << _scalar(prop.type)
          }
        else
          value = _scalar(prop.type)
        end
        p = OpenStruct.new(type: prop.type, id: prop.id, name: prop.name, value: value)
        return p
      end

      def _scalar(type)
        case type.to_sym
          when :Long    then return _integer
          when :Boolean then return (_ubyte > 0)
          when :Binary  then return @oab.read(_integer)
          when :AnsiString, :UnicodeString
            string = ''
            while (byte = @oab.read(1)) != "\x00"
              string << byte
            end
            # TODO: string.force_encoding(MapiPropertyDataType.UnicodeString ? 'UTF-8' : 'ASCII')
            string.force_encoding(type == :UnicodeString ? 'UTF-8' : 'ASCII')
            return string
        end
        raise "Unknown scalar type #{type}"
      end

      def _record(headerRecord = false)
        initialPosition = @oab.pos
        recordSize = 0
        record = Record.new
        begin
          properties = headerRecord ? @headerProperties : @oabProperties
          recordSize = _uint32
          recordPresence = @oab.read((properties.length + 7) / 8).unpack("b*").join.split('').collect{|bit| bit.to_i != 0 }
          properties.each_with_index{|prop, i|
            next unless recordPresence[i + 7 - 2 * (i % 8)]
            p = _property(prop)
            pn = p.name.to_s
            record[pn] ||= []
            record[pn] << p.value
          }
        ensure
          @oab.pos = initialPosition + recordSize
        end
        return record
      end

      def records
        @records = Enumerator.new(@totalRecords) do |y|
          @totalRecords.times { y.yield _record }
        end
        return @records
      end
    end

  end
end
