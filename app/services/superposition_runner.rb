class SuperPositionRunner
    # class that we can call anywhere in the app
    STYLES = {
            # Different writing styles with instructions for Claude: bullet, simple, chunked, structured. }
        bullet:"Rewrite the following text as clear bullet points for someone with dyslexia. Use very short sentences:\n\n%s"
        simple:"Rewrite the following in very simple language (like explaining to a 10 year old). Short words only:\n\n%s",
        chunked: "Rewrite the following with lots of white space. Short paragraphs, max 3 sentences each:\n\n%s",
        structured: "Rewrite the following with bold headers and sections so it is easy to scan:\n\n%s"
      }
    def self.call(text, user = nil)
        # Person 1 calls this function via when the start button is pressed 
        recommended = detect_density(text)
        versions = {}


        # The agentic part that the agent makes the decision on its own so not a specif path/ condition - user related. 