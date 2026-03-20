<script setup lang="ts">
defineProps<{
  mood: 'happy' | 'worried' | 'sad'
}>()

const captions: Record<string, string> = {
  happy: 'All good!',
  worried: 'Watch out!',
  sad: 'Over budget!',
}
</script>

<template>
  <div class="pet-mascot" :class="`mood-${mood}`">
    <div class="pet-face">
      <div class="pet-eyes">
        <span class="eye left-eye" />
        <span class="eye right-eye" />
      </div>
      <div class="pet-mouth" />
    </div>
    <p class="pet-caption">{{ captions[mood] }}</p>
  </div>
</template>

<style scoped>
.pet-mascot {
  display: inline-flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  border-radius: 12px;
  transition: all 0.4s ease;
}

/* ── Happy ── */
.mood-happy {
  background: #f0fff4;
  border: 1px solid #9ae6b4;
  animation: bounce 1.8s ease-in-out infinite;
}

.mood-happy .pet-face {
  background: #68d391;
}

.mood-happy .pet-mouth {
  width: 20px;
  height: 10px;
  border-radius: 0 0 12px 12px;
  border: 3px solid #276749;
  border-top: none;
}

/* ── Worried ── */
.mood-worried {
  background: #fffbeb;
  border: 1px solid #f6e05e;
  animation: wobble 1.4s ease-in-out infinite;
}

.mood-worried .pet-face {
  background: #f6e05e;
}

.mood-worried .pet-mouth {
  width: 20px;
  height: 4px;
  border-radius: 2px;
  background: #744210;
}

/* ── Sad ── */
.mood-sad {
  background: #fff5f5;
  border: 1px solid #feb2b2;
  animation: droop 2.2s ease-in-out infinite;
}

.mood-sad .pet-face {
  background: #fc8181;
}

.mood-sad .pet-mouth {
  width: 20px;
  height: 10px;
  border-radius: 12px 12px 0 0;
  border: 3px solid #742a2a;
  border-bottom: none;
}

/* ── Shared face ── */
.pet-face {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  transition: background 0.4s ease;
}

.pet-eyes {
  display: flex;
  gap: 10px;
}

.eye {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #1a202c;
  display: block;
}

.pet-caption {
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--color-heading, #1a202c);
  margin: 0;
  transition: color 0.4s ease;
}

/* ── Keyframes ── */
@keyframes bounce {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-6px); }
}

@keyframes wobble {
  0%, 100% { transform: rotate(0deg); }
  25% { transform: rotate(-4deg); }
  75% { transform: rotate(4deg); }
}

@keyframes droop {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(4px); }
}
</style>
