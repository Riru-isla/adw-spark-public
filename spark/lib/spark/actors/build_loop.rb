module Spark
  module Actors
    class BuildLoop < Actor
      include Spark::Actors::PipelineInputs

      input :stories
      output :run_tracker

      def call
        log_actor("Starting build loop for #{stories.length} stories")
        update_phase("building")

        # Sort stories by dependency order
        ordered = dependency_sort(stories)

        failed_stories = Set.new

        ordered.each_with_index do |story, idx|
          # Skip stories whose dependencies failed
          blocked_by = story.depends_on.to_a & failed_stories.to_a
          if blocked_by.any?
            log_actor("Skipping story #{story.number} — blocked by failed: #{blocked_by.join(', ')}")
            failed_stories << story.number
            next
          end

          result = BuildStory.result(
            project_slug: project_slug,
            run_id: run_id,
            logger: logger,
            mode: mode,
            project_dir: project_dir,
            story: story,
            story_index: idx,
            total_stories: ordered.length
          )

          next if result.success?

          log_actor("Story #{story.number} failed: #{result.error}")
          failed_stories << story.number
          next
        end

        self.run_tracker = Spark::Tracker::Run.load(project_slug, run_id)
        log_actor("Build loop complete")
      end

      private

      def dependency_sort(stories)
        sorted = []
        remaining = stories.dup
        resolved = Set.new

        while remaining.any?
          batch = remaining.select { |s| (s.depends_on.to_set - resolved).empty? }

          if batch.empty?
            # Circular dependency or unresolvable — just add remaining in order
            log_actor("Warning: unresolvable dependencies, adding remaining stories in order")
            sorted.concat(remaining.sort_by(&:number))
            break
          end

          batch.sort_by!(&:number)
          sorted.concat(batch)
          batch.each { |s| resolved << s.number }
          remaining -= batch
        end

        sorted
      end
    end
  end
end
