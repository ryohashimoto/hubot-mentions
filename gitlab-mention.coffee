# Description:
#   GitLabのメンションをDMで通知
#   Slack名やコメント本文は、指定したSlack channelに流れてきたGitLabのログから取得
#   (GitLabから直接取得しているわけではない)
#
# Configuration:
#   なし
#  （config.gitlab_channel_namesにGitLabのログを流しているchannelを追加)
#
# Commands:
#   なし

config =
  # GitLabのログを流しているchannel IDの配列
  gitlab_channel_names: [
      '<YOUR SLACK CHANNEL ID>'
    ]

# GitLabと連携しているチャンネルかどうか
targetChannel = (channelName) ->
  channelName in config.gitlab_channel_names

# メッセージに含まれるattachments
attachments = (message) ->
  message?.rawMessage?.attachments

# GitLabのコメント本文を含むテキスト
commentText = (message) ->
  attachments(message)[0]?.text

# textからSlackネームを抽出
# 例: '@ryo\-hashimoto' -> '@ryo-hashimoto'
# NOTE: SlackネームとGitLabのユーザー名が一致している必要がある
extractedSlackNames = (text) ->
  extracted = text.match(/@.+?\s/gi)
  return [] unless extracted
  for name in extracted
    name.replace(/[(@|\\|\s)]/g, '')

# 処理対象のメッセージかどうか
respondable = (message) ->
  # GitLabと連携しているチャンネル内のattachmentにtextがあるメッセージが対象
  # ref: https://api.slack.com/docs/message-attachments
  targetChannel(message.room) && attachments(message)? && commentText(message)?

module.exports = (robot) ->
  robot.listen(
    (message) ->
      respondable(message)
    (response) ->
      message = response.message
      for name in extractedSlackNames(commentText(message))
        # DMでattachmentを送信
        # robot.sendではなくて、chat.postMessageにする必要がある
        # ref: https://api.slack.com/methods/chat.postMessage
        data = { as_user: true, attachments: attachments(message) }
        robot.adapter.client.web.chat.postMessage "@#{name}", message.rawText, data
  )
