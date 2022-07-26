<script lang="ts">
	import { afterNavigate, goto } from '$app/navigation';

	import { onMount } from 'svelte';
	import { page } from '$app/stores';

	onMount(() => {
		if ($page.params.albumId) {
			goto('/albums/' + $page.params.albumId);
		} else {
			goto('/albums');
		}
	});
</script>
