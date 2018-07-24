# Description:
#   JIRAのメンションをDMで通知
#   Slack名やコメント本文は、指定したSlack channelに流れてきたJIRAのログから取得
#   (JIRAから直接取得しているわけではない)
#
# Configuration:
#   なし
#  （config.jira_channel_namesにJIRAのログを流しているchannelを追加)
#
# Commands:
#   なし

config =
  # JIRAのログを流しているchannel IDの配列
    jira_channel_names: [
      '<YOUR SLACK CHANNEL ID>',
    ]

# JIRAと連携しているチャンネルかどうか
targetChannel = (channelName) ->
  channelName in config.jira_channel_names

# メッセージに含まれるattachments
attachments = (message) ->
  message?.rawMessage?.attachments

# messageからJIRAのコメント本文を含むテキストを返す
commentText = (message) ->
  attachments(message)[0]?.text

# textからSlackネームを抽出
# 例: '[~ryo-hashimoto]' -> "@ryo-hashimoto"
# NOTE: SlackネームとJIRAのユーザー名が一致している必要がある
extractedSlackNames = (text) ->
  extracted = text.match(/\[~.+?]/gi)
  return [] unless extracted
  for name in extracted
    name.replace(/[\[~\]]/g, '')

# 処理対象のメッセージかどうか
respondable = (message) ->
  # Jiraと連携しているチャンネル内のattachmentにtextがあるメッセージが対象
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
        robot.adapter.client.web.chat.postMessage "@#{name}", '', data
  )
